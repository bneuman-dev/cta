require 'nokogiri'
require 'date'
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
	attr_reader :data, :noko, :headings, :predictions
	def initialize(xml, xml_div_tag, headings)
		@noko = Nokogiri::XML(xml)
		@xml_div_tag = make_xpath(xml_div_tag)
		@searches = make_xpath_searches(headings)
		@predictions = parse_by_prediction
	end

	def make_xpath_searches(headings)
		searches = {}
		root_headings = headings.delete(:root)

		headings.each do |heading, search_term|
			searches[heading] = make_xpath(search_term)
		end

		add_root_headings(searches, root_headings)
	end

	def add_root_headings(searches, root_headings)
		return searches if !root_headings

		root_headings.each do |heading, search_term|
			searches[heading] = make_xpath(search_term, rel_path=false)
		end

		return searches
	end

	def make_xpath(element_name, rel_path=true)
		xpath_root = "//" + element_name
		rel_path ? "." + xpath_root : xpath_root
	end

	def parse_by_prediction
		xpath_search(@noko, @xml_div_tag).collect do |prediction|
			pred = get_data(prediction)
			pred[:datetime] = DateTime.parse(pred[:predicted])
			pred
		end
	end

	def data
		@predictions.flatten
	end

	def get_data(prediction)
		@searches.inject({}) do |data, key_value|
			heading = key_value[0]
			search = key_value[1]
			data[heading] = xpath_search(prediction, search).text
			data
		end
	end

	def xpath_search(prediction, search)
		prediction.search(search)
	end
end

class BusXMLParser < CTAXMLParser
	def initialize(xml_file)
		headings = {    timestamp: 'tmstmp',
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
		xml = File.open(xml_file).readlines.join('')
		xml_tag = 'prd'

		super(xml, xml_tag, headings)
	end
end

class TrainXMLParser < CTAXMLParser
	def initialize(xml_file)
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
		xml = File.open(xml_file).readlines.join('')
		xml_tag = 'eta'

		super(xml, xml_tag, headings)
	end
end