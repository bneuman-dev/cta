require 'date'
require 'json'
require_relative 'xml_parser'

class Comparison
	attr_reader :busses, :trains
	def initialize(bus_id, train_id, diff_in_mins=5)
		@diff_in_mins = diff_in_mins
		bus_data = Dir.glob('*bus*.xml').collect { |xml_file| BusXMLParser.new(xml_file).data }
		train_data = Dir.glob('*train*.xml').collect { |xml_file| TrainXMLParser.new(xml_file).data }
		@busses = busses.select { |bus| bus[:stop_id] == bus_id}
		@trains = trains.select { |train| train[:stop_id] == train_id }
		@bus_id = :vehicle_id
		@train_id = :run_number
		make_datetimes
	end

	def make_datetimes
		@busses.each do |pred|
			pred[:datetime] = DateTime.parse(pred[:predicted_time])
		end

		@trains.each do |pred|
			pred[:datetime] = DateTime.parse(pred[:arrival_time])
		end
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

	def group_by_time(data)
		return [] if data == []

		base_time = data[0][:datetime]
		together = []
		rejects = []

		data.each do |datum|
			time_diff = time_diff_in_mins(base_time, datum[:datetime])
			time_diff < 10 ? together << datum : rejects << datum
		end

		[together] + group_by_time(rejects)
	end

	def group_by(data, key)
		values = data.collect { |datum| datum[key] }.uniq
		values.inject([]) do |accum, value|
			accum << select_by(data, key, value)
		end
	end

	def select_by(data, key, value)
		data.select { |datum| datum[key] == value }
	end


	def time_diff_in_mins(dt1, dt2)
		time_diff = dt1 - dt2
		diff_hours = time_diff.to_f.abs * 24
		diff_mins = diff_hours * 60
	end

	def filter_by(data, key, value)
		data.select {|datum| datum[key] == value}
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


class HTML_Doc
	attr_reader :final
	def initialize(html)
		@html = html
		@jscript = jscript
		@final = encapsulate
	end

	def encapsulate
			"<HTML><HEAD>#{@jscript}</HEAD><BODY>#{@html}</body></html>"
	end

	def jscript
		"<script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'></script>
	<script type='text/javascript' src='parse.js'></script><script type='text/javascript' src='comp.js'></script>"
	end
end

def make_html
	comper = Comparison.new("8819", "30019")
	comp = comper.compare(comper.parse_busses, comper.parse_trains)
	json = JSON_Comparisons.new(comp)
	html = HTML_Doc.new(json.html)
	filename = "html/comp-" + rand(1000).to_s + ".html"
	file = File.open(filename, 'w')
	file.write(html.final)
	file.close
end

=begin
	def group_trains
		trains_by_ids = group_by(@trains, :run_number)
		trains_by_ids.collect { |trains_with_id| group_by_time(trains_with_id)}.flatten(1)
	end

	def group_busses
		busses_by_ids = group_by(@busses, :vehicle_id)
		busses_by_ids.collect { |busses_with_id| group_by_time(busses_with_id) }.flatten(1)
	end

def collapse_close
		bus_ids = @close.collect { |datum| datum[:bus_id] }.uniq
		bus_ids.collect { |id| parse_close_by_busid(id) }.flatten
	end

	def parse_close_by_busid(id)
		data = @close.select { |datum| datum[:bus_id] == id}
		grouped_data = group_by_bus_time(data)
		grouped_data.collect { |group| make_close_hash(group)}
	end


	def make_close_hash(data)
		{bus_stop: data[0][:bus_stop],
		 bus_id: data[0][:bus_id],
		 bus_times: data.collect { |datum| datum[:bus_time] }.sort,
		 train_stop: data[0][:train_stop],
		 trains: parse_trains_data(data),}
	end

	def parse_trains_data(data)
		trains = data.collect { |datum| datum[:trains] }.flatten
		ids = get_train_ids(trains)
		ids.inject([]) do |train_array, id|
			id_trains = get_trains_by_id(trains, id)
			times = id_trains.collect { |train| train[:times] }.flatten.uniq.sort
			train_array << {id: id, times: times}
		end
	end

	def parse_close(bus, trains)
		{bus_stop: bus[:stop_id],
		 bus_id: bus[:vehicle_id],
		 bus_time: bus[:predicted_time],
		 train_stop: trains[0][:stop_id],
		 trains: parse_trains(trains)
		 }
	end

	def parse_trains(trains)
		ids = get_train_ids(trains)
		ids.inject([]) do |train_array, id|
			train_array << {
				run_number: id,
				times: get_train_times_by_id(trains, id)
			}
		end
	end

	def get_train_ids(trains)
		trains.collect { |train| train[:run_number] }.uniq
	end

	def get_trains_by_id(trains, id)
		trains.select { |train| train[:run_number] == id}
	end

	def get_train_times(trains)
		trains.collect { |train| train[:arrival_time]}
	end

	def get_train_times_by_id(trains, id)
		get_train_times(trains.select { |train| train[:run_number] == id})
	end
=end