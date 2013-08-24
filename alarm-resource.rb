require 'json'
require 'set'

class ResourceValidationException < Exception
end

class AlarmResource
  attr_reader :name

  def self.parse(name, resource_value)
    AlarmResource.new(name, resource_value)
  end

  def initialize(name, resource_value)
    @name = name
    @resource_value = resource_value
    validate
  end

  def to_s
    "AWS::CloudWatch::Alarm:
      name: #{@name},
      namespace: #{namespace},
      statistic: #{statistic},
      period: #{period},
      evaluation_periods: #{evaluation_periods},
      threshold: #{threshold},
      comparison_operator: #{comparison_operator}"
  end

  def properties
    @resource_value["Properties"]
  end

  def metric
    properties && properties["MetricName"]
  end

  def namespace
    properties && properties["Namespace"]
  end

  def statistic
    properties && properties["Statistic"]
  end

  def period
    properties && properties["Period"] && properties["Period"].to_i
  end

  def evaluation_periods
    properties && properties["EvaluationPeriods"] && properties["EvaluationPeriods"].to_i
  end

  def threshold
    properties && properties["Threshold"] && properties["Threshold"].to_i
  end

  def comparison_operator
    properties && properties["ComparisonOperator"]
  end

  def alarm_cpu?(cpu_usage)
    if metric == "CPUUtilization" then
      compare(cpu_usage, threshold, comparison_operator)
    else
      false
    end
  end

  def alarm_memory?(memory_usage)
    if metric == "MemoryUtilization" then
      compare(memory_usage, threshold, comparison_operator)
    else
      false
    end
  end

  private
  def compare(actual_value, threshold, operator)
    if operator == "GreaterThanOrEqualToThreshold" then
      actual_value >= threshold
    elsif operator == "GreaterThanThreshold" then
      actual_value > threshold
    elsif operator == "LessThanThreshold" then
      actual_value < threshold
    elsif operator == "LessThanOrEqualToThreshold" then
      actual_value <= threshold
    else
      validation_error("Unsupported comparison operator: " + operator)
    end
  end

  def validate
    warning("Unsupported period: " + period.to_s + ". Only 60 seconds is supported.") unless period == 60
    warning("Unsupported evaluation_periods: " + evaluation_periods.to_s + ". Only 1 period is supported.") unless evaluation_periods == 1
    validation_error("Unsupported metric: " + metric) unless ["MemoryUtilization", "CPUUtilization"].member?(metric)
    validation_error("Unsupported statistic: " + statistic ) unless statistic == "Average"
    validation_error("Unsupported comparison operator: " + comparison_operator) unless [ "GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"].member?(comparison_operator)
  end

  def validation_error(message)
    raise ResourceValidationException.new(@name + message)
  end

  def warning(message)
    puts message
  end
end

class TemplateUtils
  def self.template_as_json(file_path)
    JSON.parse(File.read(file_path))
  end

  def self.get_resource_type(resource_value)
    resource_value["Type"]
  end

  def self.alarm_resource?(resource_value)
    self.get_resource_type(resource_value) == "AWS::CloudWatch::Alarm"  
  end
end

class AlarmUtils
  def self.collect_alarms_from_template(file_path)
    template_content = TemplateUtils.template_as_json(file_path)
    template_resources = template_content["Resources"]

    alarms = []
    if template_resources then
      template_resources.each do |k, v|
        alarms << AlarmResource.parse(k, v) if TemplateUtils.alarm_resource?(v)
      end
    else
      puts "Error: Could not find resources in the template file"
      exit 1
    end

    alarms
  end

  def self.collect_metrics(alarm_resources)
    result = Set.new
    alarm_resources.each do |resource|
      result.add(resource.metric)
    end
    result.to_a
  end
end
