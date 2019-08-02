# frozen_string_literal: true

require "active_support/core_ext/date_and_time/zones"
require "active_support/core_ext/time/zone_class_methods"

class Time
  include DateAndTime::Zones
end
