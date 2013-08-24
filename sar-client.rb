class SarEntry
  attr_reader :cpu_usage, :memory_usage
  def initialize(cpu_usage, memory_usage)
    @cpu_usage = cpu_usage
    @memory_usage = memory_usage
  end
end

class SarClientException < Exception
end

class SarClient
  def collect_stats(interval, times)
    response = `sar -ur #{interval} #{times} | tail -n 5`
    parse_response(response)
  end

  private
  def parse_response(response)
    lines = response.split("\n")
    validate(lines)

    cpu_usage = (get_cpu_usage(lines[0], lines[1]) || get_cpu_usage(lines[3], lines[4]) )
    memory_usage = (get_memory_usage(lines[0], lines[1]) || get_memory_usage(lines[3], lines[4]) )

    SarEntry.new(cpu_usage, memory_usage)
  end

  def get_cpu_usage(header_line, content_line)
    column_index = parse_response_line(header_line).index("%idle")
    if column_index then
      100.0 - parse_response_line(content_line)[column_index].to_f
    end
  end

  def get_memory_usage(header_line, content_line)
    column_index = parse_response_line(header_line).index("%memused")
    if column_index then
      parse_response_line(content_line)[column_index].to_f
    end
  end

  def parse_response_line(line)
    line.strip.split(/\s+/)
  end

  def validate(lines)
    raise SarClientException.new("Error: Could not parse sar response!") if lines.size != 5
  end
end
