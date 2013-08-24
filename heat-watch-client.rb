class HeatWatchClient
  def metric_put_data(attrs)
    `heat-watch metric-put-data #{attrs[:stack_name]}-#{attrs[:alarm_name]} #{attrs[:namespace]} #{attrs[:metric_name]} Count 1`
  end

  def alarm(attrs)
    set_state(attrs, "ALARM")
  end

  def set_state(attrs, state)
    `heat-watch set-state #{attrs['stack_name']}-#{attrs['alarm_name']} #{state}`
  end
end
