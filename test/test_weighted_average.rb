require 'helper'

# clumsy way to unprotect these
class Object; def metaclass; class << self; self; end; end; end
ActiveRecord::Base.metaclass.send(:public, :construct_weighted_average_sql)
ActiveRecord::Base.metaclass.send(:public, :construct_update_all_weighted_averages_sql)

class TestWeightedAverage < Test::Unit::TestCase
  should "update all weighted averages, has_many through" do
    should_have_same_sql(
      AircraftClass.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
      "UPDATE `aircraft_classes` SET `aircraft_classes`.seats = (SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes`  LEFT OUTER JOIN `aircraft` ON `aircraft`.id = `airline_aircraft_seat_classes`.aircraft_id     WHERE ((`aircraft`.aircraft_class_id = `aircraft_classes`.id AND `airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id) AND (`airline_aircraft_seat_classes`.seats IS NOT NULL)) )"
    )
  end

  should "update all weighted averages" do
    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
      "UPDATE `aircraft` SET `aircraft`.seats = (SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE ((`airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id) AND (`airline_aircraft_seat_classes`.seats IS NOT NULL)) )"
    )

    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:seats, :association => :airline_aircraft_seat_classes),
      "UPDATE `aircraft` SET `aircraft`.seats = (#{AirlineAircraftSeatClass.construct_weighted_average_sql(:seats, {}, :conditions => '`airline_aircraft_seat_classes`.aircraft_id = `aircraft`.id')})"
    )
  end

  should "update all weighted averages, custom weighting" do
    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
      "UPDATE `aircraft` SET `aircraft`.distance = (SELECT (SUM(`segments`.distance * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.aircraft_id = `aircraft`.id) AND (`segments`.distance IS NOT NULL)) )"
    )

    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:distance, :by => :passengers, :association => :segments),
      "UPDATE `aircraft` SET `aircraft`.distance = (#{Segment.construct_weighted_average_sql(:distance, { :by => :passengers }, :conditions => '`segments`.aircraft_id = `aircraft`.id' )})"
    )
  end

  should "update all weighted averages, custom weighting and disaggregator" do
    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
      "UPDATE `aircraft` SET `aircraft`.payload = (SELECT (SUM(`segments`.payload / `segments`.departures_performed * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.aircraft_id = `aircraft`.id) AND (`segments`.payload IS NOT NULL)) )"
    )

    should_have_same_sql(
      Aircraft.construct_update_all_weighted_averages_sql(:payload, :by => :passengers, :association => :segments, :disaggregator => :departures_performed),
      "UPDATE `aircraft` SET `aircraft`.payload = (#{Segment.construct_weighted_average_sql(:payload, { :by => :passengers, :disaggregator => :departures_performed }, :conditions => '`segments`.aircraft_id = `aircraft`.id')})"
    )
  end

  # plain

  should "do default weighting" do
    should_have_same_sql(
      AirlineAircraftSeatClass.construct_weighted_average_sql(:seats),
      "SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE ((`airline_aircraft_seat_classes`.seats IS NOT NULL)) "
    )
  end

  should "do custom weighting" do
    should_have_same_sql(
      Segment.construct_weighted_average_sql(:distance, :by => :passengers),
      "SELECT (SUM(`segments`.distance * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.distance IS NOT NULL)) "
    )
  end

  # conditions

  # Aircraft#seats fallback value
  # a subquery used in Aircraft.update_all_seats
  should "do default weighting with conditions" do 
    conditions = 'aircraft_id = 1'
    should_have_same_sql(
      AirlineAircraftSeatClass.construct_weighted_average_sql(:seats, {}, :conditions => conditions),
      "SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE ((#{conditions}) AND (`airline_aircraft_seat_classes`.seats IS NOT NULL)) "
    )
  end

  # fake! we would never calc load factor this way
  should "do custom weighting with conditions" do
    conditions = 'aircraft_id = 1'
    should_have_same_sql(
      Segment.construct_weighted_average_sql(:load_factor, { :by => :passengers }, :conditions => conditions),
      "SELECT (SUM(`segments`.load_factor * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((#{conditions}) AND (`segments`.load_factor IS NOT NULL)) "
    )
  end

  # foreign weightings

  # fake! we would never calc seats this way
  should "do foreign default weighting" do
    should_have_same_sql(
      Aircraft.construct_weighted_average_sql(:seats, :association => :airline_aircraft_seat_classes),
      "SELECT (SUM(`aircraft`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `aircraft` LEFT OUTER JOIN `airline_aircraft_seat_classes` ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE ((`aircraft`.seats IS NOT NULL)) "
    )
  end

  # Aircraft#m3 fallback value
  # a subquery used in Aircraft.update_all_m3s
  should "do foreign custom weighting" do
    should_have_same_sql(
      Aircraft.construct_weighted_average_sql(:m3, :by => :passengers, :association => :segments),
      "SELECT (SUM(`aircraft`.m3 * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `aircraft` LEFT OUTER JOIN `segments` ON segments.aircraft_id = aircraft.id WHERE ((`aircraft`.m3 IS NOT NULL)) "
    )
  end

  # scoped

  should "do default weighting, scoped" do
    conditions = '`aircraft`.`aircraft_id` = 1'
    should_have_same_sql(
      AirlineAircraftSeatClass.scoped(:conditions => conditions).construct_weighted_average_sql(:seats),
      "SELECT (SUM(`airline_aircraft_seat_classes`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `airline_aircraft_seat_classes` WHERE ((`airline_aircraft_seat_classes`.seats IS NOT NULL)) AND (#{conditions}) "
    )
  end

  should "do custom weighting, scoped" do
    conditions = '`segments`.`aircraft_id` = 5'
    should_have_same_sql(
      Segment.scoped(:conditions => conditions).construct_weighted_average_sql(:load_factor, :by => :passengers),
      "SELECT (SUM(`segments`.load_factor * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.load_factor IS NOT NULL)) AND (#{conditions}) "
    )
  end

  # scoped foreign weightings

  should "do foreign default weighting, scoped" do
    conditions = '`aircraft`.`seats` > 5'
    should_have_same_sql(
      Aircraft.scoped(:conditions => conditions).construct_weighted_average_sql(:seats, :association => :airline_aircraft_seat_classes),
      "SELECT (SUM(`aircraft`.seats * `airline_aircraft_seat_classes`.weighting) / SUM(`airline_aircraft_seat_classes`.weighting)) AS weighted_average FROM `aircraft` LEFT OUTER JOIN `airline_aircraft_seat_classes` ON airline_aircraft_seat_classes.aircraft_id = aircraft.id WHERE ((`aircraft`.seats IS NOT NULL)) AND (#{conditions}) "
    )
  end

  should "do foreign custom weighting, scoped" do
    conditions = '`aircraft`.`m3` > 1'
    should_have_same_sql(
      Aircraft.scoped(:conditions => conditions).construct_weighted_average_sql(:m3, :by => :passengers, :association => :segments),
      "SELECT (SUM(`aircraft`.m3 * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `aircraft` LEFT OUTER JOIN `segments` ON segments.aircraft_id = aircraft.id WHERE ((`aircraft`.m3 IS NOT NULL)) AND (#{conditions}) "
    )
  end

  # disaggregation (limited testing)

  should "do custom weighting with disaggregation" do
    should_have_same_sql(
      Segment.construct_weighted_average_sql(:load_factor, :by => :passengers, :disaggregator => :departures_performed),
      "SELECT (SUM(`segments`.load_factor / `segments`.departures_performed * `segments`.passengers) / SUM(`segments`.passengers)) AS weighted_average FROM `segments` WHERE ((`segments`.load_factor IS NOT NULL)) "
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
    assert_equal args[0].gsub(/\s+/, ' '), args[1].gsub(/\s+/, ' ')
  end
end
