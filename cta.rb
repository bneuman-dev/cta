require 'open-uri'
require_relative 'xml_parser'
require 'debugger'

def stop_ids 
	["8816", "8819", "1802", "4954", "8955", "8951", "8942"]
end

module CTAFetcher
	BUS_KEY = "p9NLSAchMtx4qYD4v93Nr2CdJ"
	BUS_BASE_URL = "http://www.ctabustracker.com/bustime/api/v1/getpredictions/?key="
	TRAIN_KEY = '4cb5b729ba3e4d97b3d47697131d01e4'
	TRAIN_BASE_URL = "http://lapi.transitchicago.com/api/1.0/ttarrivals.aspx?key="

	def fetch_train_prediction(stpid, rt=nil)
		url = TRAIN_BASE_URL + TRAIN_KEY + "&mapid=#{stpid}"
		url += "&rt=#{rt}" if rt
		xml = open(url).read
		train_xml_parser(xml)
	end

	def fetch_bus_prediction(stpid, rt=nil)
		url = BUS_BASE_URL + BUS_KEY + "&stpid=#{stpid}"
		url += "&rt=#{rt}" if rt
		xml = open(url).read
		debugger
		bus_xml_parser(xml)
	end
end