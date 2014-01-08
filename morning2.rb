require_relative 'cta.rb'
require_relative 'xml_parser.rb'


def morning
	bus = BusPrediction.new(stop_ids, 50)
	train = TrainPrediction.new(40090)
	bus_xml = bus_xml_parser(bus.get_data)
	train_xml = train_xml_parser(train.get_data)
	[bus_xml.data, train_xml.data]
end

def start?
	(Time.new(2014, 1, 7, 22, 50) - Time.now)/60 < 2
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


until start?
 	sleep 200
	puts "not started yet"
end

until Time.now > Time.new(2014, 1, 7, 22, 56) 
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

ready