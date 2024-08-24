# frozen_string_literal: true

require 'maxminddb'
require_relative '../errors/geoip_error'

class GeoIPService
  class << self
    def load_database
      db_path = Config.geoip_db_path
      raise GeoIPError::DatabaseError, 'GEOIP_DB_PATH is not set' if db_path.nil?

      unless File.exist?(db_path)
        raise GeoIPError::DatabaseError,
              "GeoIP database file not found at #{db_path}"
      end

      MaxMindDB.new(db_path)
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

      result
    end

    private

    def valid_ip?(ip)
      IPAddr.new(ip)
      true
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
