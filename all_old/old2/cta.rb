require 'open-uri'

def stop_ids
	{:DamenArgyleSouth => "8816",
		:DamenEastwoodSouth => "8819",
		:ClarkBrynMawrSouth => "1802",
		:DamenEastWoodNorth => "4954",
		:DamenMontroseNorth => "8955",
		:DamenIrvingNort => "8951",
		:DamenBelmontNorth => "8942",}
end

def stop_now_ids
	{:DamenArgyleSouth => "8816",
		:DamenEastwoodSouth => "8819",}
end

class Bus_Prediction
	def initialize(stops, rt)
		@stops = stops
		@rt = rt.to_s
		#@xml = get_xml
		#write_xml
	end

	def bus_key
		"p9NLSAchMtx4qYD4v93Nr2CdJ"
	end

	def base_url
		"http://www.ctabustracker.com/bustime/api/v1/getpredictions/?key=" + bus_key
	end

	def url
		stops = @stops.values.join(',')
		"#{base_url}&rt=#{@rt}&stpid=#{stops}"
	end
		
	def get_xml
		open(url).readlines.join('')
	end

	def write_xml
		file_exists = true
		while file_exists
			filename = "cta-" + "bus-" + @rt + "-" + rand(10000).to_s + ".xml"
			file_exists = false unless File.exists?(filename)
		end

		file = File.open(filename, 'w')
		file.write(@xml)
		file.close
	end
end

class Train_Prediction
	def initialize(mapid, rt=nil)
		@mapid = mapid.to_s
		@rt = rt
		@url = station_url
		#@xml = get_xml
		#write_xml
	end

	def train_key
		'4cb5b729ba3e4d97b3d47697131d01e4'
	end

	def base_url
		"http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key=" + train_key
	end

	def station_url
		url = base_url + "&mapid=" + @mapid
		url += "&rt=#{@rt}" if @rt
		url
	end

	def get_xml
		open(@url).readlines.join('')
	end

	def write_xml
		file_exists = true
		while file_exists
			filename = "cta-" + "train" + @mapid + "-" + rand(1000).to_s + ".xml"
			file_exists = false unless File.exists?(filename)
		end

		file = File.open(filename, 'w')
		file.write(@xml)
		file.close
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
end

def ready
	while true
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
end