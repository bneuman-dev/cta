require_relative 'cta.rb'
require_relative 'xml_parser.rb'
require_relative 'morning2.rb'
require 'debugger'

def make_prediction(route, stop)
  trains = ['red', 'blue', 'brn', 'g', 'org', 'p', 'pink', 'y']

  if trains.include? route
    pred = TrainPrediction.new(stop, route)
    train_xml_parser(pred.get_data).data

  else
    pred = BusPrediction.new(stop, route)
    bus_xml_parser(pred.get_data).data
  end
end

class TripPredictions
  attr_reader :preds

  def initialize(route, depart_stop, end_stop)
    @depart = make_prediction(route, depart_stop)
    @arrive = make_prediction(route, end_stop)
    @preds = make_trip_preds
  end

  def make_trip_preds
    @depart.reduce([]) do |pairs, dep_pred|
      id = dep_pred[:id]
      end_pred = @arrive.find { |prediction| prediction[:id] == id}
      pairs << {dep: dep_pred, arr: end_pred}
    end
  end
end

class TripPredIntersections
  attr_reader :intersections, :trip1_preds, :trip2_preds

  def initialize(trip1_preds, trip2_preds)
    @trip1_preds = trip1_preds
    @trip2_preds = trip2_preds
    @intersections = get_data
  end

  def get_data
    @trip1_preds.reject { |pred| !pred[:arr] }
    .collect do |pred|
      intersection = get_intersection_data(pred)
      intersection[:trip1] = pred
      intersection
    end
  end

  def get_intersection_data(pred)
    intersection = find_intersection(pred, @trip2_preds)
    next_index = @trip2_preds.index(intersection) + 1
    following_trip = @trip2_preds.fetch(next_index, "none")
    {trip2: intersection, trip2_next: following_trip}
  end

  def find_intersection(pred, trip_preds)
    intersection = trip_preds.find do |trip_pred|
      trip_pred[:dep][:predicted] > pred[:arr][:predicted]
    end

    intersection.nil? ? trip_preds[0] : intersection
  end
end

class MultiIntersections
  attr_reader :int1, :int2

  def initialize(*intses)
    @intses = intses
  end

  def do
  
    intsies = @intses.dup
    ints1 = intsies.shift
    int1 = ints1[0]
    unities = [unite(int1, intsies[0])]

    until intsies.size == 1
      intsies.shift
      next_int = unity1[0]
      unities << unite(next_int, intsies.shift)
    end

    unities
  end


  def unite(int, ints2)
    inter_intersection = ints2.find do |int2|
      int2[:trip1] == int[:trip2]
    end

    [int, inter_intersection]
  end
end

class TripIntersections
  attr_reader :super_int
  def initialize(trip1, trip2, trip3)
    @trip1 = trip1
    @trip2 = trip2
    @trip3 = trip3
    get_predictions
    get_first_intersection
    get_second_intersection
    @super_int = get_three_inter
  end

  def get_predictions
    @trip1_pred = TripPredictions.new(*@trip1).preds
    @trip2_pred = TripPredictions.new(*@trip2).preds
    @trip3_pred = TripPredictions.new(*@trip3).preds
  end

  def get_first_intersection
    @inter1 = TripPredIntersections.new(@trip1_pred, @trip2_pred).intersections
  end

  def get_second_intersection
    @inter2 = TripPredIntersections.new(@trip2_pred, @trip3_pred).intersections
  end

  def get_three_inter
    meet = @inter2.intersections.find do |inter|
      inter[:trip1] == @inter1.intersections[0][:trip2]
    end

    @inter1.dup[:trip3] = meet
  end
end




def dodo
  trip1 = TripPredictions.new(50, '8816', '8819')
  trip2 = TripPredictions.new(81, '3760', '3769')
  trip3 = TripPredictions.new(36, '5347', '5363')
end


def preds

  trip1 = TripPredictions.new(50, '8816', '8819')
  trip2 = TripPredictions.new(81, '3760', '3769')
  trip3 = TripPredictions.new(36, '5347', '5363')
  
  int1 = TripPredIntersections.new(trip1.preds, trip2.preds)
  int2 = TripPredIntersections.new(trip2.preds, trip3.preds)
  [trip1, trip2, trip3, int1, int2]
end

def dodo2
  # trip1 = [50, '8816', '8819']
  # trip2 = [81, '3760', '3769']
    # trip3 = [36, '5347', '5363']
    # TripIntersections.new(trip1, trip2, trip3)



  MultiIntersections.new(int1, int2)
end


