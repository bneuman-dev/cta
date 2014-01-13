require 'nokogiri'
#For trains one XML file covers ONE station. Can contain multiple <eta></eta> elements describing different trains with different ETAs into that one station.


#For busses one XML file can contain multiple <prd></prd> elements, each of which describes the prediction for one bus.
#Single request can have multiple busses.


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
			get_data(prediction)
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
			 arrival_or_departure: 'typ',
			 stop_id: 'stpid',
			 stop_name: 'stpnm',
			 vehicle_id: 'vid',
			 feet_left_to_stop: 'dstp',
			 route: 'rt',
			 route_dir: 'rtdir',
			 predicted_time: 'prdtm',
			 delayed: 'dly',
			}

		xml_tag = 'prd'

		super(xml_file, xml_tag, headings)
	end
end

class TrainXMLParser < CTAXMLParser
	def initialize(xml_file)
		headings = 	{
			root: {timestamp: "tmst"},
			station_id: "staId",
			stop_id: "stpId",
			station_name: "staNm",
			platform_name: "stpDe",
			run_number: "rn",
			route_name: "rt",
			destination_stpd_id: "destSt",
			destination_name: "destNm",
			direction_code: "trDr",
			arrival_time: "arrT",
			is_approaching: "isApp",
			is_scheduled_prediction: "isSch",
			fault_detected: "isFlt",
			delay_detected: "isDly",
			latitude: "lat",
			longitude: "lon",
		}

		xml_tag = 'eta'

		super(xml_file, xml_tag, headings)
	end
end