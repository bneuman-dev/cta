class DataCollection
  attr_reader :data
  def initialize(data, filters = {})
    @data = data
    @protected_data = @data.dup
    filters.each { |key, value| select_by!(key, value) }
  end

  def revert
    @data = @protected_data
  end

  def sort_by!(keys)
    @data = sort_by(keys)
  end

  def sort_by(keys)
    @data.sort do |x,y|
      order_by_keys(keys, x, y)
    end
  end

  def order_by_keys(keys, x, y)
    order = 0 
    i = 0
    until order != 0 || i == keys.length
      key = keys[i]
      order = (x[key] <=> y[key])
      i += 1
    end
    order
  end
  
  def group_by_time!
    @data = group_by_time
  end

  def group_by_time
    time_grouping(@data)
  end

  def group_by!(key)
    @data = group_by(key)
  end

  def group_by(key)
    values = @data.collect { |datum| datum[key] }.uniq
    values.inject([]) do |accum, value|
      accum << select_by(key, value)
    end
  end

  def select_by(key, value)
    @data.select { |datum| datum[key] == value }
  end

  def select_by!(key, value)
    @data.select! { |datum| datum[key] == value }
  end

  def time_grouping(data)
    return [] if data == []

    base_time = data[0][:datetime]
    together = []
    rejects = []

    data.each do |datum|
      time_diff = time_diff_in_mins(base_time, datum[:datetime])
      time_diff < 10 ? together << datum : rejects << datum
    end

    [together] + time_grouping(rejects)
  end

  def time_diff_in_mins(dt1, dt2)
    time_diff = dt1 - dt2
    diff_hours = time_diff.to_f.abs * 24
    diff_mins = diff_hours * 60
  end
end

class Comparison
  attr_reader :busses, :trains
  def initialize(bus_id, train_id, diff_in_mins=5)
    @diff_in_mins = diff_in_mins
    bus_data = Dir.glob('*bus*.xml').collect { |xml_file| BusXMLParser.new(xml_file).data }
    train_data = Dir.glob('*train*.xml').collect { |xml_file| TrainXMLParser.new(xml_file).data }
    @busses = CTADataCollection.new(bus_data, stop_id: bus_id)
    @trains = CTADataCollection.new(train_data, stop_id: train_id)
    @bus_id = :vehicle_id
    @train_id = :run_number
    make_datetimes
  end

  def compare(x_groups, y_groups)
    x_groups.inject([]) do |accum, x_group| 
      y_intersections = compare_x_group_and_y_groups(x_group, y_groups)
      accum << [x_group, y_intersections]
    end
  end

  def compare_x_group_and_y_groups(x_group, y_groups)
    x_times = x_group[:times]
    y_groups.select do |y_group|
      y_times = y_group[:times]
      times_intersect?(x_times, y_times)
    end
  end

  def times_intersect?(x_group, y_group)
    x_group.any? do |x_time|
      y_group.any? do |y_time|
        time_diff_in_mins(x_time, y_time) < @diff_in_mins
      end
    end
  end

  def parse_busses
    group_then_parse(@busses, @bus_id)
  end

  def parse_trains
    group_then_parse(@trains, @train_id)
  end


  def group_then_parse(data, id_key)
    grouped = group_by_id_then_time(data, id_key)
    grouped.collect { |grouping| parse_group(grouping, id_key) }
  end

  def parse_group(data, id_key)
    {stop_id: data[0][:stop_id],
     id: data[0][id_key],
     times: data.collect { |datum| datum[:datetime] }
    }
  end

  def group_by_id_then_time(data, id)
    data_by_ids = group_by(data, id)
    data_by_ids.collect { |data_with_id| group_by_time(data_with_id) }.flatten(1)
  end
end

class JSON_Comparisons
  attr_reader :comparisons
  def initialize(comparisons)
    @comparisons = comparisons.dup
  end

  def html
    @comparisons.collect { |comparison| html_it(comparison) }.join
  end

  def html_it(comparison)
    ids = comparison.flatten.collect { |comp| comp[:id]}
    label = ids.join(' & ')
    json = json_it(comparison)
    make_html(json, label)
  end

  def json_it(comparison)
    lines = comparison.flatten.inject([]) do |lines, flat|
        lines << 
          { stop_id: flat[:stop_id],
          id: flat[:id],
        times: times_to_strings(flat[:times])
        }
    end
    JSON.generate(lines)
  end

  def make_html(json, label)
    label ? tag_id = "id='#{label}'" : tag_id = ""
    "<div class='json' #{tag_id}>#{json}</div>"
  end

  def times_to_strings(times)
    times.uniq.sort.collect {|time| time.strftime("%H:%M:%S")}
  end
end
