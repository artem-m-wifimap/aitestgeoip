# frozen_string_literal: true

require 'maxminddb'
require_relative '../../config/config'
require_relative '../errors/geoip_error'

class GeoIPService
  class << self
    def load_database
      raise GeoIPError::DatabaseError, 'GEOIP_DB_PATH is not set' if Config.geoip_db_path.nil?

      unless File.exist?(Config.geoip_db_path)
        raise GeoIPError::DatabaseError,
              "GeoIP database file not found at #{Config.geoip_db_path}"
      end

      MaxMindDB.new(Config.geoip_db_path)
    rescue Errno::ENOENT, Errno::EACCES => e
      raise GeoIPError::DatabaseError, "Error accessing GeoIP database: #{e.message}"
    end

    def db
      @db ||= load_database
    end

    def lookup(ip)
      raise GeoIPError::InvalidIP, 'Invalid IP address' unless valid_ip?(ip)

      result = db.lookup(ip)
      raise GeoIPError::IPNotFound, 'IP address not found in the database' unless result.found?

      build_result(ip, result)
    end

    private

    def valid_ip?(ip)
      IPAddr.new(ip)
      true
    rescue IPAddr::InvalidAddressError
      false
    end

    def build_result(ip, result)
      {
        ip: ip,
        country: result.country.name,
        country_code: result.country.iso_code,
        city: result.city.name,
        postal_code: result.postal.code,
        latitude: result.location.latitude,
        longitude: result.location.longitude,
        time_zone: result.location.time_zone
      }
    end
  end
end
