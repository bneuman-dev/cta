require_relative 'cta'
require_relative 'xml_parser'
require_relative 'morning2'


#My idea of what a 'prediction' or 'route' looks like is constrained by the CTA API. 
#E.g., a single prediction only predicts an arrival at one stop because of how train API lookups work.
#Bus APIs allow looking up more than one stop at once, but the train doesn't. If I want to abstract I have to pretend
#you can only look up one bus stop at once.
#Do I? What if I abstract TrainPrediction so you can treat it like BusPrediction? Hm!
# Also, wouldn't have this constraint if I regularly mined ALL data from CTA.

include CTAFetcher

class IntersectingTripFinder
  attr_reader :intersecting_trips

  def initialize(first_trip_predictions, second_trip_predictions)
    @first_trip_predictions = first_trip_predictions
    @second_trip_predictions = second_trip_predictions
    @intersecting_trips = find_intersecting_trips
    filter_out_non_intersections
    get_trips_following_intersections
  end

  def find_intersecting_trips
    @first_trip_predictions.collect do |first_trip_prediction|
      second_trip_prediction = find_intersecting_trip(first_trip_prediction, @second_trip_predictions)
      {first_trip: first_trip_prediction, second_trip: second_trip_prediction}
    end
  end

  def find_intersecting_trip(first_trip_prediction, second_trip_predictions)
    second_trip_predictions.find do |second_trip_prediction|
      second_trip_prediction[:dep][:predicted] > first_trip_prediction[:arr][:predicted]
    end
  end

  def filter_out_non_intersections
    @intersecting_trips.reject! { |intersection| intersection[:second_trip].nil? }
  end

  def get_trips_following_intersections
    @intersecting_trips.each do |intersection|
      second_trip_index = @second_trip_predictions.index(intersection[:second_trip])
      following_trip = @second_trip_predictions[second_trip_index + 1]
      intersection[:follow_up] = following_trip unless following_trip.nil?
    end
  end

  def intersections
    @intersecting_trips
  end
end


class IntersectionsIntersectionsFinder

  attr_reader :inter_ints
  def initialize(intersections1, intersections2)
    @ints1 = intersections1
    @ints2 = intersections2
    @inter_ints = find_intersections_intersections(@ints1, @ints2)
  end

  def find_intersections_intersections(intersections1, intersections2)
    inter_intersections = intersections1.collect do |int1|
      int2 = intersections2.find { |int2| int2[:trip1] == int1[:trip2] }
      {int1: int1, int2: int2}
    end
  end

  def filter_out_nil
    @inter_ints.reject! { |inter_int| inter_int.values.include? nil }
  end

  def format
    @inter_ints.collect! do |inter_int|
      [inter_int[:int1][:trip1], inter_int[:int1][:trip2], inter_int[:int2][:trip2]]
    end
  end
end



def test
  trip1 = get_predictions_for_trip(50, '8816', '8819')
  trip2 = get_predictions_for_trip(81, '3760', '3769')
  trip3 = get_predictions_for_trip(36, '5347', '5363')
  int1 = IntersectingTripFinder.new(trip1, trip2).intersections
  int2 = IntersectingTripFinder.new(trip2, trip3).intersections
  [trip1, trip2, trip3, int1, int2]
end


