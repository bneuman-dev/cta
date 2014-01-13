require 'open-uri'
require 'nokogiri'
require 'json'

class CTA_Train_Prediction
	def initialize(mapid)
		@mapid = mapid.to_s
		@url = station_url(@mapid)
		@xml = open(@url).readlines.join('')
		write_xml(@xml)
	end

	def train_key
		'4cb5b729ba3e4d97b3d47697131d01e4'
	end

	def base_url
		"http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key=" + train_key
	end

	def station_url(mapid)
		base_url + "&mapid=" + mapid
	end

	def write_xml(xml)
		file_exists = true
		while file_exists
			filename = "cta-" + @mapid + "-" + rand(1000000).to_s + ".xml"
			file_exists = false unless File.exists?(filename)
		end

		file = File.open(filename, 'w')
		file.write(xml)
		file.close
	end
end

class Predictions_Parser
	def initialize(xml_file)
		@xml = File.open(xml_file).readlines.join('')
		@noko = Nokogiri::XML(@xml)
		@predictions = @noko.search('.//eta')
		@parsed = parse_predictions
		write_json
	end

	def parse_predictions
		@predictions.collect {|prediction| Train_Prediction_Parser.new(prediction)}
	end

	def results
		@parsed.collect {|pred| pred.parsed}
	end

	def json_results(results)
		JSON.generate(results)
	end

	def encapsulate_json(json)
		"<HTML><HEAD><script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'></script>
<script type='text/javascript' src='parse.js'></script></HEAD><BODY><div id='json'>#{json}</div></body></html>"
	end

	def write_json
		filename = 'json/json-' + rand(1000000).to_s + ".html"
		while File.exists? filename
			filename = 'json/json-' + rand(1000000).to_s + ".html"
		end
		file = File.open(filename, 'w')
		json = json_results(results)
		html = encapsulate_json(json)
		file.write(html)
		file.close
	end
end

class Train_Prediction_Parser
	attr_reader :parsed
	def initialize(prediction)
		@searches = {
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
		@prediction = prediction
		@parsed = do_searches
	end

	def xpath_search(xpath)
		@prediction.search(xpath)
	end

	def make_xpath(child_name)
		".//" + child_name
	end

	def get_element(element_name)
		xpath = make_xpath(element_name)
		search = xpath_search(xpath)
		search.text
	end

	def do_searches
		@searches.inject({}) do |results, key_value|
			results[key_value[0]] = get_element(key_value[1])
			results
		end
	end
end


def repeat
	while true
		CTA_Train_Prediction.new(40090)
		sleep 120
	end
end

repeat
