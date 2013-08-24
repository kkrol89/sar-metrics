#!/usr/bin/env ruby

DEFAULT_RC_FILE="/etc/ec2-credentials.rc"
TARGET="/opt/sar-metrics/"
TARGET_TEMPLATE = TARGET + "scaling.template"
TARGET_SCRIPT = TARGET + "metrics-job.rb"
CRON_FILE="/etc/sar-cronjob"

require_relative 'alarm-resource'
require_relative 'heat-watch-client'

def print_usage
  puts "Usage: metrics-setup file.template stack-name"
end

if ARGV.size != 2 then
  print_usage
  exit 1
end

template_file_path = ARGV[0]
alarms = AlarmUtils.collect_alarms_from_template(template_file_path)
stack_name = ARGV[1]

puts "Found alarms: #{alarms}"
puts "Calling heat-watch metric-put-data..."

heat_watch_client = HeatWatchClient.new
alarms.each do |alarm|
  heat_watch_client.metric_put_data({
    stack_name: stack_name,
    alarm_name: alarm.name,
    namespace: alarm.namespace,
    metric_name: alarm.metric
  }) if false
end

puts "Installing sar-metrics"
`mkdir #{TARGET}` unless File.exists?(TARGET)
`cp *.rb #{TARGET}`
`chmod +x #{TARGET_SCRIPT}`
puts "Copying template file..."
`cp #{template_file_path} #{TARGET_TEMPLATE}`
puts "Creating crontab entry..."
`echo "*/1 * * * * source #{DEFAULT_RC_FILE} && #{TARGET_SCRIPT} #{TARGET_TEMPLATE} #{stack_name}" > #{CRON_FILE}`
puts "Reloading crontab..."
`crontab #{CRON_FILE}`
puts "Done."
