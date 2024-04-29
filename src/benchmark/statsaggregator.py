# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import datetime
import json
import logging
import threading
import time
from typing import Optional

import numpy as np

from .oairequester import RequestStats

logger = logging.getLogger()

class _Samples:
   def __init__(self):
      # [0] timestamp, [1] value
      self.samples:[(float, float)] = []

   def _trim_oldest(self, duration:float):
      while len(self.samples) > 0 and (time.time() - self.samples[0][0]) > duration:
         self.samples.pop(0)

   def _append(self, timestamp:float, value:float):
      self.samples.append((timestamp, value))

   def _values(self) -> [float]:
      values = []
      for entry in self.samples:
         values.append(entry[1])
      return values
   
   def _len(self) -> int:
      return len(self.samples)

class _StatsAggregator(threading.Thread):
   """
   A thread-safe request stats aggregator that can periodically emit statistics.
   """
   lock = threading.Lock()
   terminate: threading.Event

   start_time: float = 0
   processing_requests_count: int = 0
   total_requests_count: int = 0
   total_failed_count: int = 0
   throttled_count: int = 0

   request_timestamps = _Samples()
   request_latency = _Samples()
   call_tries = _Samples()
   response_latencies = _Samples()
   first_token_latencies = _Samples()
   token_latencies = _Samples()
   context_tokens = _Samples()
   generated_tokens = _Samples()
   utilizations = _Samples()

   def __init__(self, clients:int, dump_duration:float=5, window_duration:float=60, expected_gen_tokens: Optional[int] = None, json_output=False, *args,**kwargs):
      """
      :param clients: number of clients being used in testing.
      :param dump_duration: duration in seconds to dump current aggregates.
      :param window_duration: duration of sliding window in second to consider for aggregation.
      :param expected_gen_tokens: number of tokens expected in each response.
      :param json_output: whether to dump periodic stats as json or human readable.
      """
      self.clients = clients
      self.dump_duration = dump_duration
      self.json_output = json_output
      self.window_duration = window_duration
      self.expected_gen_tokens = expected_gen_tokens

      super(_StatsAggregator, self).__init__(*args, **kwargs)


   def dump_raw_call_stats(self):
      """Dumps raw stats for each individual call within the aggregation window"""
      samples = {
         "request_timestamps": [round(val, 4) for val in self.request_timestamps._values()],
         "request_latency": [round(val, 4) for val in self.request_latency._values()],
         "call_tries": self.call_tries._values(),
         "response_latencies": [round(val, 4) for val in self.response_latencies._values()],
         "first_token_latencies": [round(val, 4) for val in self.first_token_latencies._values()],
         "token_latencies": [round(val, 5) for val in self.token_latencies._values()],
         "context_tokens": self.context_tokens._values(),
         "generated_tokens": self.generated_tokens._values(),
         "utilizations": self.utilizations._values(),
      }
      logger.info(f"All data samples: {json.dumps(samples)}")

   def run(self):
      """
      Start the periodic aggregator. Use stop() to stop.
      """
      self.start_time = time.time()
      self.terminate = threading.Event()
      while not self.terminate.wait(self.dump_duration):
         self._dump()
         self._slide_window()

   def stop(self):
      self.terminate.set()
      # Dump one more time to ensure we include the final request
      self._dump()

   def record_new_request(self):
      """
      Records a new request, so that the number of processing requests is known.
      """
      with self.lock:
         self.processing_requests_count += 1

   def aggregate_request(self, stats: RequestStats):
      """
      Aggregates request stat within the sliding window.
      :param stats: request stats object.
      """
      with self.lock:
         self.processing_requests_count -= 1
         self.total_requests_count += 1
         self.call_tries._append(stats.request_start_time, stats.calls)
         if stats.response_status_code != 200:
            self.total_failed_count += 1
            if stats.response_status_code == 429:
               self.throttled_count += 1
         else:
            request_latency = stats.response_end_time - stats.request_start_time
            self.request_latency._append(stats.request_start_time, request_latency)
            if request_latency > self.window_duration:
               logging.warning((
                     f"request completed in {round(request_latency, 2)} seconds, while aggregation-window is {round(self.window_duration, 2)} "
                     "seconds, consider increasing aggregation-window to at least 2x your typical request latency."
                  )
               )   
            self.request_timestamps._append(stats.request_start_time, stats.request_start_time)
            self.response_latencies._append(stats.request_start_time, stats.response_time - stats.request_start_time)
            self.first_token_latencies._append(stats.request_start_time, stats.first_token_time - stats.request_start_time)
            self.token_latencies._append(stats.request_start_time, (stats.response_end_time - stats.first_token_time) / stats.generated_tokens)
            self.context_tokens._append(stats.request_start_time, stats.context_tokens)
            self.generated_tokens._append(stats.request_start_time, stats.generated_tokens)
         if stats.deployment_utilization is not None:
            self.utilizations._append(stats.request_start_time, stats.deployment_utilization)

   def _dump(self):
      with self.lock:
         run_seconds = round(time.time() - self.start_time)
         # Use dynamic aggregation window for when elapsed duration < window_duration
         dynamic_window = min(run_seconds, self.window_duration)
         timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
         e2e_latency_avg = round(np.average(self.request_latency._values()), 3) if self.request_latency._len() > 0 else "n/a"
         e2e_latency_95th = round(np.percentile(self.request_latency._values(), 95), 3) if self.request_latency._len() > 1 else "n/a"
         context_per_minute = round(60.0 * np.sum(self.context_tokens._values()) / dynamic_window, 0) if self.context_tokens._len() > 0 else "n/a"
         gen_per_minute = round(60.0 * np.sum(self.generated_tokens._values()) / dynamic_window, 0) if self.generated_tokens._len() > 0 else "n/a"
         tokens_per_minute = 0
         if context_per_minute != "n/a":
            tokens_per_minute += context_per_minute
         if gen_per_minute != "n/a":
            tokens_per_minute += gen_per_minute
         context_tpr_avg = int(np.sum(self.context_tokens._values()) / self.context_tokens._len()) if self.context_tokens._len() > 0 else "n/a"
         gen_tpr_avg = int(np.sum(self.generated_tokens._values()) / self.generated_tokens._len()) if self.generated_tokens._len() > 0 else "n/a"
         gen_tpr_10th = int(np.percentile(self.generated_tokens._values(), 10)) if self.generated_tokens._len() > 1 else "n/a"
         gen_tpr_90th = int(np.percentile(self.generated_tokens._values(), 90)) if self.generated_tokens._len() > 1 else "n/a"
         ttft_avg = round(np.average(self.first_token_latencies._values()), 3) if self.first_token_latencies._len() > 0 else "n/a"
         ttft_95th = round(np.percentile(self.first_token_latencies._values(), 95), 3) if self.first_token_latencies._len() > 1 else "n/a"
         tbt_avg = round(np.average(self.token_latencies._values()), 3) if self.token_latencies._len() > 0 else "n/a"
         tbt_95th = round(np.percentile(self.token_latencies._values(), 95), 3) if self.token_latencies._len() > 1 else "n/a"
         util_avg = f"{round(np.average(self.utilizations._values()), 1)}%" if self.utilizations._len() > 0 else "n/a"
         util_95th = f"{round(np.percentile(self.utilizations._values(), 95), 1)}%" if self.utilizations._len() > 1 else "n/a"
         rpm = round(60.0 * self.request_timestamps._len() / dynamic_window, 1)  if self.request_timestamps._len() > 0 else "n/a"
         # Periodically warn if generated TPR is consistently lower than requested, which can result in higher scores for RPM compared to reality
         warning_period_secs = 10
         if all((
            run_seconds % warning_period_secs == 0,
            self.expected_gen_tokens is not None,
            isinstance(gen_tpr_avg, int)
         )) and gen_tpr_avg < 0.9 * self.expected_gen_tokens:
            logging.warning(
               (
                  f"average tokens per response is {gen_tpr_avg}, compared to requested max_tokens of {self.expected_gen_tokens}."
                  " this may mean measured rpm is higher and e2e request latency is faster than in real-world workloads"
                  " (tpm, ttft & tbt stats will still be accurate)."
               )
            )
         # Handle the 1x extra processing_request due to next request being queued
         processing_requests_count = min(self.clients, self.processing_requests_count)
         if self.json_output:
            j = {
               "run_seconds": run_seconds,
               "timestamp": timestamp,
               "rpm": rpm,
               "processing": processing_requests_count,
               "completed": self.total_requests_count,
               "failures": self.total_failed_count,
               "throttled": self.throttled_count,
               "requests": self.total_requests_count,
               "tpm": {
                  "context": context_per_minute,
                  "gen": gen_per_minute,
                  "total": tokens_per_minute,
               },
               "e2e": {
                  "avg": e2e_latency_avg,
                  "95th": e2e_latency_95th,
               },
               "ttft": {
                  "avg": ttft_avg,
                  "95th": ttft_95th,
               },
               "tbt": {
                  "avg": tbt_avg,
                  "95th": tbt_95th,
               },
               "context_tpr_avg": context_tpr_avg,
               "gen_tpr": {
                  "10th": gen_tpr_10th,
                  "avg": gen_tpr_avg,
                  "90th": gen_tpr_90th,
               },
               "util": {
                  "avg": util_avg,
                  "95th": util_95th,
               },
            }
            logger.info(json.dumps(j))
         else:
            logger.info(f"rpm: {rpm:<5} processing: {processing_requests_count:<4} completed: {self.total_requests_count:<5} failures: {self.total_failed_count:<4} throttled: {self.throttled_count:<4} requests: {self.total_requests_count:<5} tpm: {tokens_per_minute:<6} ttft_avg: {ttft_avg:<6} ttft_95th: {ttft_95th:<6} tbt_avg: {tbt_avg:<6} tbt_95th: {tbt_95th:<6} e2e_avg: {e2e_latency_avg:<6} e2e_95th: {e2e_latency_95th:<6} context_tpr_avg {context_tpr_avg:<4} gen_tpr_10th {gen_tpr_10th:<4} gen_tpr_avg {gen_tpr_avg:<4} gen_tpr_90th {gen_tpr_90th:<4} util_avg: {util_avg:<6} util_95th: {util_95th:<6}")

   def _slide_window(self):
      with self.lock:
         self.call_tries._trim_oldest(self.window_duration)
         self.request_timestamps._trim_oldest(self.window_duration)
         self.response_latencies._trim_oldest(self.window_duration)
         self.first_token_latencies._trim_oldest(self.window_duration)
         self.token_latencies._trim_oldest(self.window_duration)
         self.context_tokens._trim_oldest(self.window_duration)
         self.generated_tokens._trim_oldest(self.window_duration)
         self.utilizations._trim_oldest(self.window_duration)
