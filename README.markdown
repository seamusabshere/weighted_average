# weighted_average

Do weighted averages in ARel.

## Rationale

You have a bunch of flight records with passenger count and distance.

* Flight EWR <-> MSN; 30,000 passengers last month; 500 miles
* Flight EWR <-> BOM; 15 passengers last month; 10,000 miles

The average distance is <tt>(10_000 + 500) / 2 = 5250</tt>.

The average distance weighted by passenger count is <tt>(30_000 * 500 + 15 * 10_000) / (10_500) = 1442</tt>.

## Usage

Using <tt>FlightSegment</tt> from [Brighter Planet's earth library](http://rubygems.org/gems/earth):

    >> FlightSegment.weighted_average(:distance, :weighted_by => :passengers)
    => 2436.1959

You can also see the SQL that is generated:

    >> FlightSegment.weighted_average_relation(:distance, :weighted_by => :passengers).to_sql
    => "SELECT (SUM((`flight_segments`.`distance`) * `flight_segments`.`passengers`) / SUM(`flight_segments`.`passengers`)) AS weighted_average FROM `flight_segments` WHERE (`flight_segments`.`distance` IS NOT NULL)"

## Copyright

Copyright (c) 2012 Brighter Planet, Inc.
