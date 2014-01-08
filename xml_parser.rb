require 'nokogiri'
require 'date'
require 'json'
#For trains one XML file covers ONE station. Can contain multiple <eta></eta> elements describing different trains with different ETAs into that one station.


#For busses one XML file can contain multiple <prd></prd> elements, each of which describes the prediction for one bus.
#Single request can have multiple busses.

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

class CTAXMLParser
	attr_reader :data, :noko_xml, :root_headings
	def initialize(xml, prediction_key, headings)
		@noko_xml = Nokogiri::XML(xml)
		@prediction_key = prediction_key
		@headings = headings
		@root_headings = headings.delete(:root)
		@root_data = get_root_data
		@data = get_data
	end

	def get_data
		divide_by_prediction.collect do |prediction|
			data = search(prediction, @headings)
			data = add_datetime(data)
			data.merge(@root_data)
		end
	end

	def get_root_data
		@root_headings ? search(@noko_xml, @root_headings) : {}
	end

	def add_datetime(prediction)
		prediction[:datetime] = DateTime.parse(prediction[:predicted])
		prediction
	end

	def search(xml, headings)
		data = {}
		headings.each do |heading, search_key|
			data[heading] = get_text_from_xml(xml, search_key)
		end
		return data
	end

	def get_text_from_xml(xml, search_key)
		xml_search(xml, search_key).text
	end

	def xml_search(xml, search_key)
		xml.search(".//#{search_key}")
	end

	def divide_by_prediction
		xml_search(@noko_xml, @prediction_key)
	end

	def write_json(filename)
		file = File.open(filename, 'w')
		file.write(JSON.generate(@data))
		file.close
	end

end

def bus_xml_parser_f(xml_file)
	xml = File.open(xml_file).readlines.join('')
	bus_xml_parser(xml)
end

def train_xml_parser_f(xml_file)
	xml = File.open(xml_file).readlines.join('')
	train_xml_parser(xml)
end

def bus_xml_parser(xml)
	
	prediction_tag = 'prd'
	headings = 	{    
			 timestamp: 'tmstmp',
			 stop_id: 'stpid',
			 stop_name: 'stpnm',
			 id: 'vid',
			 predicted: 'prdtm',
			 scheduled: 'typ',
			 delayed: 'dly',
			 route: 'rt',
			 direction: 'rtdir',
			 feet_left_to_stop: 'dstp',
			}
	CTAXMLParser.new(xml, prediction_tag, headings)
end

def train_xml_parser(xml)
	prediction_tag = 'eta'

	headings = 	{
			root: {timestamp: "tmst"},
			stop_id: "stpId",
			stop_name: "stpDe",
			id: "rn",
			predicted: "arrT",
			scheduled: "isSch",
			delayed: "isDly",
			route: "rt",
			direction: "trDr",
			approaching: "isApp",
			fault: "isFlt",
			station_id: "staId",
			station_name: "staNm",
			destination_stpd_id: "destSt",
			destination_name: "destNm",
		}

	CTAXMLParser.new(xml, prediction_tag, headings)
end