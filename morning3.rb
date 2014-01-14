require_relative 'cta'
require_relative 'intersection'

include CTAFetcher

def morn
  while true
    damen = CTAFetcher.get_predictions_for_trip(50, '8016', '8019')
    brown = CTAFetcher.get_predictions_for_trip('brn', '30019', '30091')
    damen.each do |dam|
      puts "Damen bus predicted at #{dam[:dep][:predicted]} due to arrive at Easwood at #{dam[:arr][:predicted]}"
    end

    brown.each do |br|
      puts "Train predicted at #{br[:dep][:predicted]} due to arrive at MM at #{br[:arr][:predicted]}"
    end

    sleep 120
  end
end