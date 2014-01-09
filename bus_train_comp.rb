require 'date'
require 'json'
require_relative 'xml_parser'




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
