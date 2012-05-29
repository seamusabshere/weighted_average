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
      "SELECT SUM(airline_aircraft_seat_classes.weighting * airline_aircraft_seat_classes.seats * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM airline_aircraft_seat_classes WHERE airline_aircraft_seat_classes.seats IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      AirlineAircraftSeatClass.weighted_average_relation('seats')
    )
  end
  
  it "does custom weighting" do
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.distance * 1.0) / SUM(segments.passengers) FROM segments WHERE segments.distance IS NOT NULL AND segments.passengers > 0",
      Segment.weighted_average_relation('distance', :weighted_by => 'passengers')
    )
  end
  
  # nothing but nils
  
  it "returns nil if the values to be weighted are all nil" do
    Segment.weighted_average(:mail, :weighted_by => :passengers).must_be_nil
    Segment.weighted_average(:seats, :weighted_by => :passengers).wont_be_nil
  end
  
  # multiple columns
  
  it "adds multiple columns before averaging" do
    should_have_same_sql(
      "SELECT SUM(airline_aircraft_seat_classes.weighting * (airline_aircraft_seat_classes.seats + airline_aircraft_seat_classes.pitch) * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM airline_aircraft_seat_classes WHERE airline_aircraft_seat_classes.seats IS NOT NULL AND airline_aircraft_seat_classes.pitch IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      AirlineAircraftSeatClass.weighted_average_relation(['seats', 'pitch'])
    )
  end
  
  # conditions
  
  # a subquery used in Aircraft.update_all_seats
  it "does default weighting with conditions" do 
    conditions = "aircraft_id = #{rand(1e11)}"
    
    should_have_same_sql(
      "SELECT SUM(airline_aircraft_seat_classes.weighting * airline_aircraft_seat_classes.seats * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM airline_aircraft_seat_classes WHERE (#{conditions}) AND airline_aircraft_seat_classes.seats IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      AirlineAircraftSeatClass.where(conditions).weighted_average_relation('seats')
    )
  end
  
  # note fake condition
  it "does custom weighting with conditions" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.load_factor * 1.0) / SUM(segments.passengers) FROM segments WHERE (456 = 456) AND segments.load_factor IS NOT NULL AND segments.passengers > 0",
      Segment.where(conditions).weighted_average_relation('load_factor', :weighted_by => 'passengers')
    )
  end
  
  # foreign weightings
  
  # fake! we would never calc seats this way
  it "does foreign default weighting" do
    should_have_same_sql(
      "SELECT SUM(airline_aircraft_seat_classes.weighting * aircraft.seats * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM aircraft INNER JOIN airline_aircraft_seat_classes ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE aircraft.seats IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      Aircraft.weighted_average_relation('seats', :weighted_by => :airline_aircraft_seat_classes)
    )
  end
    
  # Aircraft#m3 fallback value
  # a subquery used in Aircraft.update_all_m3s
  it "does foreign custom weighting" do
    should_have_same_sql(
      "SELECT SUM(segments.passengers * aircraft.m3 * 1.0) / SUM(segments.passengers) FROM aircraft INNER JOIN segments ON segments.bts_aircraft_type = aircraft.bts_aircraft_type WHERE aircraft.m3 IS NOT NULL AND segments.passengers > 0",
      Aircraft.weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  it "does foreign custom weighting with custom join keys" do
    should_have_same_sql(
      "SELECT SUM(segments.passengers * aircraft_deux.m3 * 1.0) / SUM(segments.passengers) FROM aircraft_deux INNER JOIN segments ON segments.bts_aircraft_type = aircraft_deux.my_bts_aircraft_type_code WHERE aircraft_deux.m3 IS NOT NULL AND segments.passengers > 0",
      AircraftDeux.weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # scoped
  
  it "does default weighting, scoped" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT SUM(airline_aircraft_seat_classes.weighting * airline_aircraft_seat_classes.seats * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM airline_aircraft_seat_classes WHERE (#{conditions}) AND airline_aircraft_seat_classes.seats IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      AirlineAircraftSeatClass.scoped(:conditions => conditions).weighted_average_relation(:seats)
    )
  end
  
  it "does custom weighting, scoped" do
    conditions = '999 = 999'
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.load_factor * 1.0) / SUM(segments.passengers) FROM segments WHERE (#{conditions}) AND segments.load_factor IS NOT NULL AND segments.passengers > 0",
      Segment.scoped(:conditions => conditions).weighted_average_relation(:load_factor, :weighted_by => :passengers)
    )
  end
  
  # # scoped foreign weightings
  
  it "does foreign default weighting, scoped" do
    conditions = '454 != 999'
    should_have_same_sql(
      "SELECT SUM(airline_aircraft_seat_classes.weighting * aircraft.seats * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM aircraft INNER JOIN airline_aircraft_seat_classes ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE (#{conditions}) AND aircraft.seats IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:seats, :weighted_by => :airline_aircraft_seat_classes)
    )
  end
  
  it "does foreign custom weighting, scoped" do
    conditions = 'aircraft.m3 > 1'
    should_have_same_sql(
      "SELECT SUM(segments.passengers * aircraft.m3 * 1.0) / SUM(segments.passengers) FROM aircraft INNER JOIN segments ON segments.bts_aircraft_type = aircraft.bts_aircraft_type WHERE (#{conditions}) AND aircraft.m3 IS NOT NULL AND segments.passengers > 0",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # # disaggregation
  
  it "does custom weighting with disaggregation" do
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.load_factor / segments.departures_performed * 1.0) / SUM(segments.passengers) FROM segments WHERE segments.load_factor IS NOT NULL AND segments.passengers > 0 AND segments.departures_performed > 0",
      Segment.weighted_average_relation(:load_factor, :weighted_by => :passengers, :disaggregate_by => :departures_performed)
    )
  end
  
  # # more complicated stuff
  
  it "construct weightings across has_many through associations (that can be used for updating all)" do
    aircraft_class = AircraftClass.arel_table
    aircraft = Aircraft.arel_table
    segment = Segment.arel_table
    
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.seats * 1.0) / SUM(segments.passengers) FROM segments INNER JOIN aircraft ON aircraft.bts_aircraft_type = segments.bts_aircraft_type INNER JOIN aircraft_classes ON aircraft_classes.id = aircraft.aircraft_class_id WHERE segments.seats IS NOT NULL AND segments.passengers > 0 AND aircraft.aircraft_class_id = aircraft_classes.id",
      Segment.joins(:aircraft => :aircraft_class).weighted_average_relation(:seats, :weighted_by => :passengers).where(aircraft[:aircraft_class_id].eq(aircraft_class[:id]))
    )
  end
  

  # # cohorts (requires the cohort_analysis gem)

  it "does custom weighting, with a cohort" do
    should_have_same_sql(
      "SELECT SUM(segments.passengers * segments.load_factor * 1.0) / SUM(segments.passengers) FROM segments WHERE (segments.payload = 5) AND segments.load_factor IS NOT NULL AND segments.passengers > 0",
      Segment.cohort(:payload => 5).weighted_average_relation(:load_factor, :weighted_by => :passengers)
    )
  end

  describe "on Arel::Table" do
    it "works on plain tables" do
      c = Segment.connection
      table_name = "plain_arel_table_#{rand(1e11).to_s}"
      c.execute %{
        CREATE TEMPORARY TABLE #{table_name} AS SELECT * FROM #{Segment.quoted_table_name} LIMIT 1
      }
      table = Arel::Table.new(table_name)
      should_have_same_sql(
        "SELECT SUM(#{table_name}.passengers * #{table_name}.distance * 1.0) / SUM(#{table_name}.passengers) FROM #{table_name} WHERE #{table_name}.distance IS NOT NULL AND #{table_name}.passengers > 0",
        table.weighted_average_relation('distance', :weighted_by => 'passengers')
      )
    end

    it "takes complex args" do
      should_have_same_sql(
        "SELECT SUM(airline_aircraft_seat_classes.weighting * (airline_aircraft_seat_classes.seats + airline_aircraft_seat_classes.pitch) * 1.0) / SUM(airline_aircraft_seat_classes.weighting) FROM airline_aircraft_seat_classes WHERE airline_aircraft_seat_classes.seats IS NOT NULL AND airline_aircraft_seat_classes.pitch IS NOT NULL AND airline_aircraft_seat_classes.weighting > 0",
        AirlineAircraftSeatClass.arel_table.weighted_average_relation(['seats', 'pitch'])
      )
    end
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
