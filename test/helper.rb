require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'logger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'weighted_average'

class Test::Unit::TestCase
end

$logger = Logger.new STDOUT #'test/test.log'

ActiveSupport::Notifications.subscribe do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  $logger.debug "#{event.payload[:name]} (#{event.duration}) #{event.payload[:sql]}"
end

ActiveRecord::Base.establish_connection(
  'adapter' => 'mysql',
  'database' => 'weighted_average_test',
  'username' => 'root',
  'password' => ''
)

ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable %w{aircraft airline_aircraft}
  inflect.uncountable 'commons'
  inflect.uncountable 'food'
  inflect.uncountable 'shelter'
  inflect.uncountable 'transportation'
  inflect.uncountable 'press_coverage'
  inflect.irregular 'foot', 'feet'
end

ActiveRecord::Schema.define(:version => 20090819143429) do
  create_table "segments", :force => true, :options => 'ENGINE=InnoDB default charset=utf8', :id => false do |t|
    t.integer  "aircraft_id" # should this be here?
    t.integer  "departures_performed"
    t.integer  "payload"
    t.integer  "seats"
    t.integer  "passengers"
    t.integer  "freight"
    t.integer  "mail"
    t.integer  "ramp_to_ramp"
    t.integer  "air_time"
    t.float    "load_factor"
    t.float    "freight_share"
    t.integer  "distance"
    t.integer  "departures_scheduled"
    t.string   "unique_carrier"
    t.integer  "dot_airline_id"
    t.string   "unique_carrier_name"
    t.string   "unique_carrier_entity"
    t.string   "region"
    t.string   "carrier"
    t.string   "carrier_name"
    t.integer  "carrier_group"
    t.integer  "carrier_group_new"
    t.string   "origin_airport_iata"
    t.string   "origin_city_name"
    t.integer  "origin_city_num"
    t.string   "origin_state_abr"
    t.string   "origin_state_fips"
    t.string   "origin_state_nm"
    t.string   "origin_country_iso_3166"
    t.string   "origin_country_name"
    t.integer  "origin_wac"
    t.string   "dest_airport_iata"
    t.string   "dest_city_name"
    t.integer  "dest_city_num"
    t.string   "dest_state_abr"
    t.string   "dest_state_fips"
    t.string   "dest_state_nm"
    t.string   "dest_country_iso_3166"
    t.string   "dest_country_name"
    t.integer  "dest_wac"
    t.integer  "bts_aircraft_group"
    t.integer  "bts_aircraft_type"
    t.integer  "bts_aircraft_config"
    t.integer  "year"
    t.integer  "quarter"
    t.integer  "month"
    t.integer  "bts_distance_group"
    t.string   "bts_service_class"
    t.string   "data_source"
    t.float    "seats_per_departure"
    
    t.string 'payload_units'
    t.string 'freight_units'
    t.string 'mail_units'
    t.string 'distance_units'
    
    t.datetime "created_at"
    t.datetime "updated_at"
    
    t.string   "row_hash"
  end
  execute 'ALTER TABLE segments ADD PRIMARY KEY (row_hash);'
  
  create_table "aircraft", :force => true do |t|
    t.string   "name"
    t.integer  "seats"
    t.integer  "fuel_type_id"
    t.float    "endpoint_fuel"
    t.integer  "manufacturer_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.date     "bts_begin_date"
    t.date     "bts_end_date"
    t.float    "load_factor"
    t.float    "freight_share"
    t.float    "m3"
    t.float    "m2"
    t.float    "m1"
    t.float    "distance"
    t.float    "payload"
    t.integer  "aircraft_class_id"
    t.float    "multiplier"
    t.string   "manufacturer_name"
    t.string   "brighter_planet_aircraft_class_code"
    t.integer  "weighting"
    t.integer  "bts_aircraft_type"
  end
  
  create_table "aircraft_classes", :force => true do |t|
    t.string  "name"
    t.integer "seats"
    t.integer "fuel_type_id"
    t.float   "endpoint_fuel"
    t.string  "brighter_planet_aircraft_class_code"
    t.float   "m1"
    t.float   "m2"
    t.float   "m3"
  end

  create_table "aircraft_seat_classes", :force => true do |t|
    t.integer  "aircraft_id"
    t.integer  "seat_class_id"
    t.integer  "seats"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "multiplier"
    t.boolean  "fresh"
  end

  create_table "airline_aircraft", :force => true do |t|
    t.integer  "airline_id"
    t.integer  "aircraft_id"
    t.integer  "seats"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.float    "total_seat_area"
    t.float    "average_seat_area"
    t.boolean  "fresh"
    t.float    "multiplier"
  end

  create_table "airline_aircraft_seat_classes", :force => true do |t|
    t.integer  "seats"
    t.float    "pitch"
    t.float    "width"
    t.float    "multiplier"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "seat_area"
    t.string   "name"
    t.integer  "airline_id"
    t.integer  "aircraft_id"
    t.integer  "seat_class_id"
    t.integer  "weighting"
    t.integer  "peers"
  end
  
end

class Segment < ActiveRecord::Base
  set_primary_key :row_hash
end

class AirlineAircraftSeatClass < ActiveRecord::Base
  # include CohortScope

  # belongs_to :airline, :class_name => 'Airline', :foreign_key => 'airline_id'
  belongs_to :aircraft, :class_name => 'Aircraft', :foreign_key => 'aircraft_id'
  # belongs_to :seat_class, :class_name => 'SeatClass', :foreign_key => 'seat_class_id'
  has_one :aircraft_class, :class_name => 'AircraftClass', :through => :aircraft
end


class Aircraft < ActiveRecord::Base
  belongs_to :aircraft_class, :class_name => 'AircraftClass', :foreign_key => 'aircraft_class_id'
  # belongs_to :manufacturer, :class_name => 'Manufacturer', :foreign_key => 'manufacturer_id'
  # has_many :airline_aircraft, :class_name => 'AirlineAircraft'
  # has_many :seat_classes, :class_name => 'AircraftSeatClass'
  has_many :segments, :class_name => "Segment"
  has_many :airline_aircraft_seat_classes, :class_name => 'AirlineAircraftSeatClass'
end

class AircraftClass < ActiveRecord::Base
  has_many :aircraft, :class_name => 'Aircraft'
  has_many :airline_aircraft_seat_classes, :through => :aircraft
end
