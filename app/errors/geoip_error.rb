# frozen_string_literal: true

# app/errors/geoip_error.rb
module GeoIPError
  class InvalidIP < StandardError; end
  class IPNotFound < StandardError; end
  class DatabaseError < StandardError; end
end
