require 'nokogiri'
require 'json'


#stop_id, vehicle_id
#stop_id, run_number
class PredictionsSorter
	attr_reader :bus_data, :train_data, :data
	def initialize(data, sorting_method)
		@bus_data = batch_bus
		@train_data = batch_train
		@data = {bus: @bus_data, train: @train_data}
		@bus_sort_keys = [:vehicle_id, :stop_id, :timestamp]
		@train_sort_keys = [:run_number, :stop_id, :timestamp]
	end

	def batch_bus
		Dir.glob('*bus*.xml').collect { |xml_file| CTA_XML_Bus_Parser.new(xml_file).data }
	end

	def batch_train
		Dir.glob('*train*.xml').collect { |xml_file| CTA_XML_Train_Parser.new(xml_file).data }
	end

	def filter_by_value(data, key, value)
		data.select do |datum|
			datum[key.to_sym] == value
		end
	end

	def bus_sort
		sort(@bus_data.flatten, @bus_sort_keys)
	end

	def train_sort
		sort(@train_data.flatten, @train_sort_keys)
	end

	def sort(data, keys)
		data.sort do |x,y|
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
end






class Data_To_HTML
	attr_reader :bus_html, :train_html
	def initialize
		@data = Predictions_Parser.new
		@bus_data = @data.bus_sort
		@train_data = @data.train_sort
		@bus_html = group_and_htmlify(@bus_data, :vehicle_id)
		@train_html = group_and_htmlify(@train_data, :run_number)
	end

	def group_and_htmlify(data, group_by)
		group_values = get_group_values(data, group_by)
		group_values.collect do |group_value|
			htmlify_group(data, group_by, group_value)
		end
	end

	def get_group_values(data, group_by)
		data.collect { |datum| datum[group_by] }.uniq
	end

	def htmlify_group(data, group_by, group_value)
		data = data.select { |datum| datum[group_by] == group_value }
		html = make_json_html(data, group_value)
	end

	def make_json_html(data, label=nil)
		json = JSON.generate(data)
		make_html(json, label)
	end

	def make_html(json, label)
		label ? tag_id = "id='#{@label}'" : tag_id = ""
		"<div class='json' #{tag_id}>#{@json}</div>"
	end
end

class HTML_Doc
	attr_reader :final
	def initialize(html_collection, type="bus")
		@html = html_collection.join('')
		@jscript = jscript(type)
		@final = encapsulate
	end

	def encapsulate
			"<HTML><HEAD>#{@jscript}</HEAD><BODY>#{@html}</body></html>"
	end

	def jscript(vehicle_type)
		jscript = "<script type='text/javascript' src='http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'></script>
	<script type='text/javascript' src='parse.js'></script>"
		if vehicle_type == "bus"
			jscript += bus_jscript
		elsif vehicle_type == "train"
			jscript += train_jscript
		end
		return jscript
	end

	def bus_jscript
		"<script type='text/javascript' src='bus.js'></script>"
	end

	def train_jscript
		"<script type='text/javascript' src='train.js'></script>"
	end
end

def write_html
	data = Data_To_HTML.new
	train = HTML_Doc.new(data.train_html, "train")
	bus = HTML_Doc.new(data.bus_html, "bus")
	train_filename = "html/train-" + rand(10000).to_s + ".html"
	while File.exists? train_filename
		train_filename = "html/train-" + rand(10000).to_s + ".html"
	end

	bus_filename = "html/bus-" + rand(10000).to_s + ".html"
	while File.exists? bus_filename
		bus_filename = "html/bus-" + rand(10000).to_s + ".html"
	end

	train_file = File.open(train_filename, 'w')
	train_file.write(train.final)
	train_file.close
	bus_file = File.open(bus_filename, 'w')
	bus_file.write(bus.final)
	bus_file.close
end