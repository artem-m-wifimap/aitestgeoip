# frozen_string_literal: true

require 'dotenv/load'

module Config
  class << self
    def geoip_db_path
      ENV['GEOIP_DB_PATH'] || './app/bin/GeoLite2-City.mmdb'
    end

    def rack_env
      ENV['RACK_ENV'] || 'development'
    end
  end
end
