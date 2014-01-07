require_relative 'cta.rb'
require_relative 'xml_parser.rb'

def morning
	bus = Bus_Prediction.new(stop_now_ids, 50)
	train = Train_Prediction.new(40090)
	bus_xml = BusXMLParser.new(bus.get_xml)
	train_xml = TrainXMLParser.new(train.get_xml)
	[bus_xml.predictions, train_xml.predictions]
end

def start?
	(Time.new(2014, 1, 7, 6, 35) - Time.now)/60 < 2
end


def nearest(busses, trains)
	argyle = get_sorted_argyle_busses(busses)
	eastwood = get_sorted_eastwood_busses(busses)
	trains = get_sorted_trains(trains)

	next_argyle = argyle[0]
	next_argyle_depart = next_argyle[:predicted_time]

	eastwood_bus = eastwood.find { |bus| bus [:vehicle_id] == next_argyle[:vehicle_id] }
	eastwood_time = eastwood_bus[:predicted_time]

	train = trains.find { |train| train[:arrival_time] > eastwood_time }
	train = trains[-1] if train == nil
	train_time = train[:arrival_time] unless train == nil || train == []
	train_index = trains.index(train) + 1 

	next_train = trains[trains.index(train) + 1] unless !train_index
	next_train_time = next_train[:arrival_time] unless next_train == [] || next_train == nil

	nearest_train_time = trains[0][:arrival_time]
	
	["Next bus at argyle at #{next_argyle_depart}. Expected to arrive at eastwood at #{eastwood_time}. Closest train time is at #{train_time}.",
	"Next train after that is at #{next_train_time}",
	"Nearest train is #{nearest_train_time}."]
end

def get_sorted_argyle_busses(busses)
	argyle = busses.select { |bus| bus[:stop_id] == "8816" }
	argyle.sort { |x, y| x[:predicted_time] <=> y[:predicted_time] }
end

def get_sorted_eastwood_busses(busses)
	eastwood = busses.select { |bus| bus[:stop_id] == "8819"}
	eastwood.sort { |x, y| x[:predicted_time] <=> y[:predicted_time] }
end

def get_sorted_trains(trains)
	trains.sort { |x, y| x[:arrival_time] <=> y[:arrival_time] }
end


until start?
 	sleep 200
	puts "not started yet"
end

until Time.now > Time.new(2014, 1, 7, 7, 35) 
	strings = []
	busses, trains = morning
	busses.select {|bus| bus[:stop_id] == "8816" }.each do |bus|
		time = bus[:predicted_time].split(' ')[-1]
		strings << "Predicted time #{time} for bus #{bus[:vehicle_id]} at stop #{bus[:stop_name]}"
	end

	trains.each do |train|
		time = train[:arrival_time].split(' ')[-1]
		strings << "Predicted time #{time} for train #{train[:run_number]} at stop #{train[:station_name]}"
	end

	busses.select {|bus| bus[:stop_id] == "8819" }.each do |bus|
		time = bus[:predicted_time].split(' ')[-1]
		strings << "Predicted time #{time} for bus #{bus[:vehicle_id]} at stop #{bus[:stop_name]}"
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

until Time.now > Time.new(2014, 1, 6, 20, 25)
	train = Train_Prediction.new(30019)
	write_xml(train.get_xml, 'train', 30019)
	sleep 90
	bus = Bus_Prediction.new(stop_ids, 50)		
	write_xml(bus.get_xml, 'bus', 50)
	sleep 90
	train = Train_Prediction.new(30091)
	write_xml(train.get_xml, 'train', 30091)
	sleep 90
	bus = Bus_Prediction.new(stop_ids, 50)		
	write_xml(bus.get_xml, 'bus', 50)
	sleep 90
end