#!/usr/bin/env ruby

LOG_FILE = "/var/log/sar-metrics-job.log"

require_relative 'alarm-resource'
require_relative 'heat-watch-client'
require_relative 'sar-client'

def print_usage
  puts "Usage: metrics-job file.template stack-name"
end

def log(message)
  `echo "#{Time.now}: #{message}" >> #{LOG_FILE}`
end

if ARGV.size != 2 then
  print_usage
  exit 1
end

stack_name = ARGV[1]
alarms = AlarmUtils.collect_alarms_from_template(ARGV[0])

log("Collecting stats...")

sar_client = SarClient.new
sar_entry = sar_client.collect_stats(2, 30)

log("cpu: #{sar_entry.cpu_usage}, memory: #{sar_entry.memory_usage}")

alarms.each do |alarm|
 if alarm.alarm_cpu?(sar_entry.cpu_usage) || alarm.alarm_memory?(sar_entry.memory_usage) then
   log("alarming: #{alarm}")
   HeatWatchClient.new.alarm({
     stack_name: stack_name,
     alarm_name: alarm.name
   })
 end 
end
