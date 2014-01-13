
# class BusPrediction
#   def initialize(stop, rt)
#     @stop = stop
#     @rt = rt.to_s
#     @bus_key = "p9NLSAchMtx4qYD4v93Nr2CdJ"
#     @base_url = "http://www.ctabustracker.com/bustime/api/v1/getpredictions/?key=" + @bus_key
#   end

#   def url
#     #stops = @stops.join(',')
#     "#{@base_url}&rt=#{@rt}&stpid=#{@stop}"
#   end

#   def get_data
#     open(url).readlines.join('')
#   end
# end

# class TrainPrediction
#   def initialize(mapid, rt=nil)
#     @mapid = mapid.to_s
#     @rt = rt
#     @train_key = '4cb5b729ba3e4d97b3d47697131d01e4'
#     @base_url = "http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key=" + @train_key
#   end

#   def url
#     url = "#{@base_url}&mapid=#{@mapid}"
#     @rt ? url += "&rt=#{@rt}" : url
#   end

#   def get_data
#     open(url).readlines.join('')
#   end
# end




# def xml_to_json(*xml_files)
#   xml_files.each do |xml_file|
#     parser = xml_file.match("bus") ? bus_xml_parser_f(xml_file) : train_xml_parser_f(xml_file)
#     filename = "json_data/" + xml_file.split('/')[-1].split('.')[0] + ".json"
#     parser.write_json(filename)
#   end
# end

# def ready
#   train1 = TrainPrediction.new(30019)
#   train2 = TrainPrediction.new(30091, 'brn')
#   bus = BusPrediction.new(stop_ids, 50)

#   while true
#     file1 = write_xml(train1.get_data, 'train', 30019)
#     file2 = write_xml(bus.get_data, 'bus', 50)
#     file3 = write_xml(train2.get_data, 'train', 30091)
#     xml_to_json(file1, file2, file3)
#     sleep 150
#   end
# end


# def bus_xml_parser_f(xml_file)
#   xml = File.open(xml_file).readlines.join('')
#   bus_xml_parser(xml)
# end

# def train_xml_parser_f(xml_file)
#   xml = File.open(xml_file).readlines.join('')
#   train_xml_parser(xml)
# end



#class MultiIntersections

#   def initialize(int1, int2)
#     @int1 = int1
#     @int2 = int2
#   end

#   def find
#     @int2.intersections.f do |inter|
#       inter[:trip1] == @int1.intersections[0][:trip2]
#     end
#   end
# end

# class TripIntersections
#   attr_reader :super_int
#   def initialize(trip1, trip2, trip3)
#     @trip1 = trip1
#     @trip2 = trip2
#     @trip3 = trip3
#     get_predictions
#     get_first_intersection
#     get_second_intersection
#     @super_int = get_three_inter
#   end

#   def get_predictions
#     @trip1_pred = TripPredictions.new(*@trip1).preds
#     @trip2_pred = TripPredictions.new(*@trip2).preds
#     @trip3_pred = TripPredictions.new(*@trip3).preds
#   end

#   def get_first_intersection
#     @inter1 = TripPredIntersections.new(@trip1_pred, @trip2_pred).intersections
#   end

#   def get_second_intersection
#     @inter2 = TripPredIntersections.new(@trip2_pred, @trip3_pred).intersections
#   end

#   def get_three_inter
#     meet = @inter2.intersections.find do |inter|
#       inter[:trip1] == @inter1.intersections[0][:trip2]
#     end

#     @inter1.dup[:trip3] = meet
#   end
# end
