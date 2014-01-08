require_relative 'cta/cta.rb'
require_relative 'cta/xml_parser.rb'

def morning
	bus = BusPrediction.new(stop_now_ids, 50)
	train = TrainPrediction.new(40090)
	bus_xml = BusXMLParser.new(bus.get_xml)
	train_xml = TrainXMLParser.new(train.get_xml)
	[bus_xml.data, train_xml.data]
end

def start?
	(Time.new(2014, 1, 8, 6, 35) - Time.now)/60 < 2
end


def nearest(busses, trains)
	argyle = busses.select { |bus| bus[:stop_id] == "8816" }
	eastwood = busses.select { |bus| bus[:stop_id] == "8819"}
	argyle_bus = argyle.sort { |x, y| x[:predicted_time] <=> y[:predicted_time] }[0]
	argyle_bus_d = argyle_bus[:predicted_time]
	eastwood_b = eastwood.find { |bus| bus[:vehicle_id] == argyle_bus[:vehicle_id] }
	eastwood_d = eastwood_b[:predicted_time]
	trains = trains.sort { |x, y| x[:arrival_time] <=> y[:arrival_time] }
	train = trains.find {|train| train[:arrival_time] > eastwood_d}
	train_time = train[:arrival_time] if train != []
	next_train = trains[trains.index(train) + 1]
	next_train_time = next_train[:arrival_time] if next_train != []
	nearest_train_time = trains[0][:arrival_time]
	["Next bus at argyle at #{argyle_bus_d}. Expected to arrive at eastwood at #{eastwood_d}. Closest train time is at #{train_time}.",
	"Next train after that is at #{next_train_time}",
	"Nearest train is #{nearest_train_time}."]
end

until start?
 	sleep 200
	puts "not started yet"
end

until Time.now > Time.new(2014, 1, 6, 7, 25) 
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