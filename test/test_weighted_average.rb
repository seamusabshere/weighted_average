require 'helper'

describe WeightedAverage do
  # it "update all weighted averages, has_many through" do
  #   should_have_same_sql(
  #     AircraftClass.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE aircraft_classes SET aircraft_classes.seats = (SELECT (SUM((airline_aircraft_seat_classes.seats * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes  LEFT OUTER JOIN aircraft ON aircraft.id = airline_aircraft_seat_classes.aircraft_id     WHERE ((aircraft.aircraft_class_id = aircraft_classes.id AND airline_aircraft_seat_classes.aircraft_id = aircraft.id) AND (airline_aircraft_seat_classes.seats IS NOT NULL)) )"
  #   )
  # end
  # 
  # it "update all weighted averages" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE aircraft SET aircraft.seats = (SELECT (SUM((airline_aircraft_seat_classes.seats * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes WHERE ((airline_aircraft_seat_classes.aircraft_id = aircraft.id) AND (airline_aircraft_seat_classes.seats IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE aircraft SET aircraft.seats = (#{AirlineAircraftSeatClass.construct_weighted_average_sql(:seats, {}, :conditions => 'airline_aircraft_seat_classes.aircraft_id = aircraft.id')})"
  #   )
  # end
  # 
  # it "update all weighted averages, custom weighting" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
  #     "UPDATE aircraft SET aircraft.distance = (SELECT (SUM((segments.distance * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE ((segments.aircraft_id = aircraft.id) AND (segments.distance IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
  #     "UPDATE aircraft SET aircraft.distance = (#{Segment.construct_weighted_average_sql(:distance, { :by => :passengers }, :conditions => 'segments.aircraft_id = aircraft.id' )})"
  #   )
  # end
  # 
  # it "update all weighted averages, custom weighting and disaggregator" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
  #     "UPDATE aircraft SET aircraft.payload = (SELECT (SUM((segments.payload / segments.departures_performed * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE ((segments.aircraft_id = aircraft.id) AND (segments.payload IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
  #     "UPDATE aircraft SET aircraft.payload = (#{Segment.construct_weighted_average_sql(:payload, { :by => :passengers, :disaggregator => :departures_performed }, :conditions => 'segments.aircraft_id = aircraft.id')})"
  #   )
  # end

  # plain

  it "does default weighting" do
    should_have_same_sql(
      "SELECT (SUM((airline_aircraft_seat_classes.seats) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes WHERE (airline_aircraft_seat_classes.seats IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      AirlineAircraftSeatClass.weighted_average_relation('seats')
    )
  end
  
  it "does custom weighting" do
    should_have_same_sql(
      "SELECT (SUM((segments.distance) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE (segments.distance IS NOT NULL) AND (segments.passengers > 0)",
      Segment.weighted_average_relation('distance', :weighted_by => 'passengers')
    )
  end
  
  # multiple columns
  
  it "adds multiple columns before averaging" do
    should_have_same_sql(
      "SELECT (SUM((airline_aircraft_seat_classes.seats + airline_aircraft_seat_classes.pitch) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes WHERE (airline_aircraft_seat_classes.seats IS NOT NULL) AND (airline_aircraft_seat_classes.pitch IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      AirlineAircraftSeatClass.weighted_average_relation(['seats', 'pitch'])
    )
  end
  
  # conditions
  
  # a subquery used in Aircraft.update_all_seats
  it "does default weighting with conditions" do 
    conditions = 'aircraft_id = 1'
    
    should_have_same_sql(
      "SELECT (SUM((airline_aircraft_seat_classes.seats) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes WHERE (#{conditions}) AND (airline_aircraft_seat_classes.seats IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      AirlineAircraftSeatClass.where(conditions).weighted_average_relation('seats')
    )
  end
  
  # note fake condition
  it "does custom weighting with conditions" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT (SUM((segments.load_factor) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE (#{conditions}) AND (segments.load_factor IS NOT NULL) AND (segments.passengers > 0)",
      Segment.where(conditions).weighted_average_relation('load_factor', :weighted_by => 'passengers')
    )
  end
  
  # foreign weightings
  
  # fake! we would never calc seats this way
  it "does foreign default weighting" do
    should_have_same_sql(
      "SELECT (SUM((aircraft.seats) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM aircraft INNER JOIN airline_aircraft_seat_classes ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE (aircraft.seats IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      Aircraft.weighted_average_relation('seats', :weighted_by => :airline_aircraft_seat_classes)
    )
  end
    
  # Aircraft#m3 fallback value
  # a subquery used in Aircraft.update_all_m3s
  it "does foreign custom weighting" do
    should_have_same_sql(
      "SELECT (SUM((aircraft.m3) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM aircraft INNER JOIN segments ON segments.bts_aircraft_type = aircraft.bts_aircraft_type WHERE (aircraft.m3 IS NOT NULL) AND (segments.passengers > 0)",
      Aircraft.weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  it "does foreign custom weighting with custom join keys" do
    should_have_same_sql(
      "SELECT (SUM((aircraft_deux.m3) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM aircraft_deux INNER JOIN segments ON segments.bts_aircraft_type = aircraft_deux.my_bts_aircraft_type_code WHERE (aircraft_deux.m3 IS NOT NULL) AND (segments.passengers > 0)",
      AircraftDeux.weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # scoped
  
  it "does default weighting, scoped" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT (SUM((airline_aircraft_seat_classes.seats) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM airline_aircraft_seat_classes WHERE (#{conditions}) AND (airline_aircraft_seat_classes.seats IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      AirlineAircraftSeatClass.scoped(:conditions => conditions).weighted_average_relation(:seats)
    )
  end
  
  it "does custom weighting, scoped" do
    conditions = '999 = 999'
    should_have_same_sql(
      "SELECT (SUM((segments.load_factor) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE (#{conditions}) AND (segments.load_factor IS NOT NULL) AND (segments.passengers > 0)",
      Segment.scoped(:conditions => conditions).weighted_average_relation(:load_factor, :weighted_by => :passengers)
    )
  end
  
  # scoped foreign weightings
  
  it "does foreign default weighting, scoped" do
    conditions = '454 != 999'
    should_have_same_sql(
      "SELECT (SUM((aircraft.seats) * airline_aircraft_seat_classes.weighting) / SUM(airline_aircraft_seat_classes.weighting)) AS weighted_average FROM aircraft INNER JOIN airline_aircraft_seat_classes ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE (454 != 999) AND (aircraft.seats IS NOT NULL) AND (airline_aircraft_seat_classes.weighting > 0)",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:seats, :weighted_by => :airline_aircraft_seat_classes)
    )
  end
  
  it "does foreign custom weighting, scoped" do
    conditions = 'aircraft.m3 > 1'
    should_have_same_sql(
      "SELECT (SUM((aircraft.m3) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM aircraft INNER JOIN segments ON segments.bts_aircraft_type = aircraft.bts_aircraft_type WHERE (aircraft.m3 > 1) AND (aircraft.m3 IS NOT NULL) AND (segments.passengers > 0)",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # disaggregation
  
  it "does custom weighting with disaggregation" do
    should_have_same_sql(
      "SELECT (SUM((segments.load_factor) / segments.departures_performed * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE (segments.load_factor IS NOT NULL) AND (segments.passengers > 0) AND (segments.departures_performed > 0)",
      Segment.weighted_average_relation(:load_factor, :weighted_by => :passengers, :disaggregate_by => :departures_performed)
    )
  end
  
  # more complicated stuff
  
  it "construct weightings across has_many through associations (that can be used for updating all)" do
    aircraft_class = AircraftClass.arel_table
    aircraft = Aircraft.arel_table
    segment = Segment.arel_table
    
    should_have_same_sql(
      "SELECT (SUM((segments.seats) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments INNER JOIN aircraft ON aircraft.bts_aircraft_type = segments.bts_aircraft_type INNER JOIN aircraft_classes ON aircraft_classes.id = aircraft.aircraft_class_id WHERE aircraft.aircraft_class_id = aircraft_classes.id AND (segments.seats IS NOT NULL) AND (segments.passengers > 0)",
      Segment.joins(:aircraft => :aircraft_class).weighted_average_relation(:seats, :weighted_by => :passengers).where(aircraft[:aircraft_class_id].eq(aircraft_class[:id]))
    )
  end
  

  # cohorts (requires the cohort_scope gem)

  it "does custom weighting, with a cohort" do
    should_have_same_sql(
      "SELECT (SUM((segments.load_factor) * segments.passengers) / SUM(segments.passengers)) AS weighted_average FROM segments WHERE segments.payload = 5 AND (segments.load_factor IS NOT NULL) AND (segments.passengers > 0)",
      Segment.big_cohort(:payload => 5).weighted_average_relation(:load_factor, :weighted_by => :passengers)
    )
  end

  private

  def database_field_quote_char
    case ActiveRecord::Base.connection.adapter_name
    when /mysql/i
      '`'
    when /postgres/i
      '"'
    end
  end

  def should_have_same_sql(*args)
    # make sure everything is an SQL string
    args.map! { |arg| arg.is_a?(String) ? arg : arg.to_sql }
    # clean up whitespace
    args.map! { |arg| arg.to_s.gsub(/\s+/, ' ').gsub(database_field_quote_char, '') }
    # treat the first arg as the "known good"
    best = args.shift
    # make sure the "best" SQL is valid
    ActiveRecord::Base.connection.execute(best)
    # compare everything to the known good
    args.each { |arg| best.must_equal arg }
  end
end
