require 'helper'

class TestWeightedAverage < Test::Unit::TestCase
  # should "update all weighted averages, has_many through" do
  #   should_have_same_sql(
  #     AircraftClass.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE `aircraft_classes` SET `aircraft_classes`.seats = (SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes`  LEFT OUTER JOIN `aircraft` ON `aircraft`.id = `airline_aircraft_seat_classes`.aircraft_id     WHERE ((`aircraft`.aircraft_class_id = `aircraft_classes`.id AND `airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id) AND (`airline_aircraft_seat_classes`.seats IS NOT NULL)) )"
  #   )
  # end
  # 
  # should "update all weighted averages" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE `aircraft` SET `aircraft`.seats = (SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE ((`airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id) AND (`airline_aircraft_seat_classes`.seats IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
  #     "UPDATE `aircraft` SET `aircraft`.seats = (#{AirlineAircraftSeatClass.construct_weighted_average_sql(:seats, {}, :conditions => '`airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id')})"
  #   )
  # end
  # 
  # should "update all weighted averages, custom weighting" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
  #     "UPDATE `aircraft` SET `aircraft`.distance = (SELECT (SUM(`segments`.distance * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.aircraft_id = `aircraft`.id) AND (`segments`.distance IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
  #     "UPDATE `aircraft` SET `aircraft`.distance = (#{Segment.construct_weighted_average_sql(:distance, { :by => :passengers }, :conditions => '`segments`.aircraft_id = `aircraft`.id' )})"
  #   )
  # end
  # 
  # should "update all weighted averages, custom weighting and disaggregator" do
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
  #     "UPDATE `aircraft` SET `aircraft`.payload = (SELECT (SUM(`segments`.payload / `segments`.departures_performed * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.aircraft_id = `aircraft`.id) AND (`segments`.payload IS NOT NULL)) )"
  #   )
  # 
  #   should_have_same_sql(
  #     Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
  #     "UPDATE `aircraft` SET `aircraft`.payload = (#{Segment.construct_weighted_average_sql(:payload, { :by => :passengers, :disaggregator => :departures_performed }, :conditions => '`segments`.aircraft_id = `aircraft`.id')})"
  #   )
  # end

  # plain

  should "do default weighting" do
    should_have_same_sql(
      "SELECT (SUM(`airline_aircraft_seat_classes`.`seats` * `airline_aircraft_seat_classes`.`weighting`) / SUM(`airline_aircraft_seat_classes`.`weighting`)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE (`airline_aircraft_seat_classes`.`seats` IS NOT NULL)",
      AirlineAircraftSeatClass.weighted_average_relation('seats')
    )
  end
  
  should "do custom weighting" do
    should_have_same_sql(
      "SELECT (SUM(`segments`.`distance` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average FROM `segments` WHERE (`segments`.`distance` IS NOT NULL)",
      Segment.weighted_average_relation('distance', :weighted_by => 'passengers')
    )
  end
  
  # conditions
  
  # a subquery used in Aircraft.update_all_seats
  should "do default weighting with conditions" do 
    conditions = 'aircraft_id = 1'
    
    should_have_same_sql(
      "SELECT (SUM(`airline_aircraft_seat_classes`.`seats` * `airline_aircraft_seat_classes`.`weighting`) / SUM(`airline_aircraft_seat_classes`.`weighting`)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE (#{conditions}) AND (`airline_aircraft_seat_classes`.`seats` IS NOT NULL)",
      AirlineAircraftSeatClass.where(conditions).weighted_average_relation('seats')
    )
  end
  
  # note fake condition
  should "do custom weighting with conditions" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT (SUM(`segments`.`load_factor` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average FROM `segments` WHERE (#{conditions}) AND (`segments`.`load_factor` IS NOT NULL)",
      Segment.where(conditions).weighted_average_relation('load_factor', :weighted_by => 'passengers')
    )
  end
  
  # foreign weightings
  
  # fake! we would never calc seats this way
  should "do foreign default weighting" do
    should_have_same_sql(
      "SELECT (SUM(`aircraft`.`seats` * `airline_aircraft_seat_classes`.`weighting`) / SUM(`airline_aircraft_seat_classes`.`weighting`)) AS weighted_average, 12345 FROM `aircraft` LEFT OUTER JOIN `airline_aircraft_seat_classes` ON `airline_aircraft_seat_classes`.`aircraft_id` = `aircraft`.`id` WHERE (`aircraft`.`seats` IS NOT NULL)",
      Aircraft.weighted_average_relation('seats', :weighted_by => :airline_aircraft_seat_classes)
    )
  end
  
  # Aircraft#m3 fallback value
  # a subquery used in Aircraft.update_all_m3s
  should "do foreign custom weighting" do
    should_have_same_sql(
      "SELECT (SUM(`aircraft`.`m3` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average, 12345 FROM `aircraft` LEFT OUTER JOIN `segments` ON `segments`.`aircraft_id` = `aircraft`.`id` WHERE (`aircraft`.`m3` IS NOT NULL)",
      Aircraft.weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # scoped
  
  should "do default weighting, scoped" do
    conditions = '456 = 456'
    should_have_same_sql(
      "SELECT (SUM(`airline_aircraft_seat_classes`.`seats` * `airline_aircraft_seat_classes`.`weighting`) / SUM(`airline_aircraft_seat_classes`.`weighting`)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE (#{conditions}) AND (`airline_aircraft_seat_classes`.`seats` IS NOT NULL)",
      AirlineAircraftSeatClass.scoped(:conditions => conditions).weighted_average_relation(:seats)
    )
  end
  
  should "do custom weighting, scoped" do
    conditions = '999 = 999'
    should_have_same_sql(
      "SELECT (SUM(`segments`.`load_factor` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average FROM `segments` WHERE (#{conditions}) AND (`segments`.`load_factor` IS NOT NULL)",
      Segment.scoped(:conditions => conditions).weighted_average_relation(:load_factor, :weighted_by => :passengers)
    )
  end
  
  # scoped foreign weightings
  
  should "do foreign default weighting, scoped" do
    conditions = '454 != 999'
    should_have_same_sql(
      "SELECT (SUM(`aircraft`.`seats` * `airline_aircraft_seat_classes`.`weighting`) / SUM(`airline_aircraft_seat_classes`.`weighting`)) AS weighted_average, 12345 FROM `aircraft` LEFT OUTER JOIN `airline_aircraft_seat_classes` ON `airline_aircraft_seat_classes`.`aircraft_id` = `aircraft`.`id` WHERE (#{conditions}) AND (`aircraft`.`seats` IS NOT NULL)",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:seats, :weighted_by => :airline_aircraft_seat_classes)
    )
  end
  
  should "do foreign custom weighting, scoped" do
    conditions = '`aircraft`.`m3` > 1'
    should_have_same_sql(
      "SELECT (SUM(`aircraft`.`m3` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average, 12345 FROM `aircraft` LEFT OUTER JOIN `segments` ON `segments`.`aircraft_id` = `aircraft`.`id` WHERE (#{conditions}) AND (`aircraft`.`m3` IS NOT NULL)",
      Aircraft.scoped(:conditions => conditions).weighted_average_relation(:m3, :weighted_by => [:segments, :passengers])
    )
  end
  
  # disaggregation
  
  should "do custom weighting with disaggregation" do
    should_have_same_sql(
      "SELECT (SUM(`segments`.`load_factor` / `segments`.`departures_performed` * `segments`.`passengers`) / SUM(`segments`.`passengers`)) AS weighted_average FROM `segments` WHERE (`segments`.`load_factor` IS NOT NULL)",
      Segment.weighted_average_relation(:load_factor, :weighted_by => :passengers, :disaggregate_by => :departures_performed)
    )
  end

  # cohorts

  # should "do custom weighting, cohort" do
  #   should_have_same_sql(
  #     Segment.cohort(:payload => 5).construct_weighted_average_sql(:load_factor, :by => :passengers),
  #     "SELECT (SUM(`segments`.load_factor * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.load_factor IS NOT NULL)) AND (`segments`.`payload` = 5) "
  #   )
  # end

  private

  def should_have_same_sql(*args)
    # make sure everything is an SQL string
    args.map! { |arg| arg.is_a?(String) ? arg : arg.to_sql }
    # clean up whitespace
    args.map! { |arg| arg.to_s.gsub /\s+/, ' ' }
    # treat the first arg as the "known good"
    best = args.shift
    # compare everything to the known good
    args.each { |arg| assert_equal best, arg }
    # make sure the SQL is valid
    assert_nothing_raised { ActiveRecord::Base.connection.execute best }
  end
end
