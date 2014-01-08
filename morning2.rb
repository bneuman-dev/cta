require_relative 'cta.rb'
require_relative 'xml_parser.rb'


def morning
	bus = BusPrediction.new(stop_ids, 50)
	train = TrainPrediction.new(40090)
	bus_xml = bus_xml_parser(bus.get_data)
	train_xml = train_xml_parser(train.get_data)
	[bus_xml.data, train_xml.data]
end

def leaving?
	time = Time.now
	time.hour == 12 && time.min > 35
end

def left?
	time = Time.now
	time.hour == 12 && time.min > 37
end

def logging?
	Time.now.hour < 22
end

def depart?
	time.hour > 5
end

# class Task
# 	def initialize(task, start_time, end_time)
# 		@task = task
# 		@start_time = start_time
# 		@end_time = end_time

# 	end
#*ctas = [[{bus: 3319}, {bus: 3323}], [{train: 3320}, {train: 3330}]]
#validate to make sure that start/end are both bus/both train/same rt
# option to have no arrival - don't care?

def cta_intersection(*ctas)
	predictions = ctas.collect { |cta| get_prediction(cta) }
	#need some way to group together 'start stop' and 'end stop'
end

def get_prediction(cta)
	prediction = cta[:vehicle] == bus ? BusPrediction.new(cta[:id]) : TrainPrediction.new(cta[:id])
	prediction.get_data
end

def get_departure_arrival(depart_stop, arrival_stop)
	id = depart_stop[:id]
	arrival = arrival_stop.find { |vehicle| vehicle[:id] == id }
	arrival_time = arrival[:predicted]
end

def get_arrival_departure(arrival_stop, depart_stop)
	arrival_time = arrival_stop[:predicted]
	depart_stop = depart_stop.find { |vehicle| vehicle[:predicted] > arrival_time }
	#what if depart_stop == nil
end

def nearest(busses, trains)
	argyle = get_sorted_argyle_busses(busses)
	eastwood = get_sorted_eastwood_busses(busses)
	trains = get_sorted_trains(trains)

	next_argyle = argyle[0]
	next_argyle_depart = next_argyle[:predicted]

	eastwood_bus = eastwood.find { |bus| bus [:id] == next_argyle[:id] }
	eastwood_time = eastwood_bus[:predicted]

	train = trains.find { |train| train[:predicted] > eastwood_time }
	train = trains[-1] if train == nil
	train_time = train[:predicted] unless train == nil || train == []
	train_index = trains.index(train) + 1 

	next_train = trains[trains.index(train) + 1] unless !train_index
	next_train_time = next_train[:predicted] unless next_train == [] || next_train == nil

	nearest_train_time = trains[0][:predicted]
	
	["Next bus at argyle at #{next_argyle_depart}. Expected to arrive at eastwood at #{eastwood_time}. Closest train time is at #{train_time}.",
	"Next train after that is at #{next_train_time}",
	"Nearest train is #{nearest_train_time}."]
end

def get_sorted_argyle_busses(busses)
	argyle = busses.select { |bus| bus[:stop_id] == "8816" }
	argyle.sort { |x, y| x[:predicted] <=> y[:predicted] }
end

def get_sorted_eastwood_busses(busses)
	eastwood = busses.select { |bus| bus[:stop_id] == "8819"}
	eastwood.sort { |x, y| x[:predicted] <=> y[:predicted] }
end

def get_sorted_trains(trains)
	trains.sort { |x, y| x[:predicted] <=> y[:predicted] }
end

while true
	until leaving?
	 	sleep 20
		puts "not started yet"
	end

	until left?
		strings = []
		busses, trains = morning
		busses.select {|bus| bus[:stop_id] == "8816" }.each do |bus|
			time = bus[:predicted].split(' ')[-1]
			strings << "Predicted time #{time} for bus #{bus[:id]} at stop #{bus[:stop_name]}"
		end

		trains.each do |train|
			time = train[:predicted].split(' ')[-1]
			strings << "Predicted time #{time} for train #{train[:id]} at stop #{train[:station_name]}"
		end

		busses.select {|bus| bus[:stop_id] == "8819" }.each do |bus|
			time = bus[:predicted].split(' ')[-1]
			strings << "Predicted time #{time} for bus #{bus[:id]} at stop #{bus[:stop_name]}"
		end

		strings << nearest(busses, trains)
		strings.flatten!
		strings.each do |string|
			puts string
			puts ""
		end

		joke = File.open('morning-data.txt', 'a')
		strings.each {|string| joke.write(string + '\n')} 
		joke.close
		sleep 150
	end

	while logging?
		ready
	end

end
