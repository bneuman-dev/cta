require 'open-uri'
require_relative 'xml_parser'

def stop_ids 
	["8816", "8819", "1802", "4954", "8955", "8951", "8942"]
end

class BusPrediction
	def initialize(stops, rt)
		@stops = stops
		@rt = rt.to_s
		@bus_key = "p9NLSAchMtx4qYD4v93Nr2CdJ"
		@base_url = "http://www.ctabustracker.com/bustime/api/v1/getpredictions/?key=" + @bus_key
	end

	def url
		stops = @stops.join(',')
		"#{@base_url}&rt=#{@rt}&stpid=#{stops}"
	end

	def get_data
		open(url).readlines.join('')
	end
end

class TrainPrediction
	def initialize(mapid, rt=nil)
		@mapid = mapid.to_s
		@rt = rt
		@train_key = '4cb5b729ba3e4d97b3d47697131d01e4'
		@base_url = "http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key=" + @train_key
	end

	def url
		url = @base_url + "&mapid=" + @mapid
		@rt ? url += "&rt=#{@rt}" : url
	end

	def get_data
		open(url).readlines.join('')
	end
end

def write_xml(xml, string, id)
	file_exists = true
	while file_exists
		filename = "cta-" + string + "-" + id.to_s + "-" + rand(10000).to_s + ".xml"
		file_exists = false unless File.exists?(filename)
	end
	file = File.open(filename, 'w')
	file.write(xml)
	file.close
	filename
end

def xml_to_json(*xml_files)
	xml_files.each do |xml_file|
		parser = xml_file.match("bus") ? bus_xml_parser_f(xml_file) : train_xml_parser_f(xml_file)
		filename = "json_data/" + xml_file.split('/')[-1].split('.')[0] + ".json"
		parser.write_json(filename)
	end
end

def ready
	train1 = TrainPrediction.new(30019)
	train2 = TrainPrediction.new(30091, 'brn')
	bus = BusPrediction.new(stop_ids, 50)

	while true
		file1 = write_xml(train1.get_data, 'train', 30019)
		file2 = write_xml(bus.get_data, 'bus', 50)
		file3 = write_xml(train2.get_data, 'train', 30091)
		xml_to_json(file1, file2, file3)
		sleep 150
	end
end
