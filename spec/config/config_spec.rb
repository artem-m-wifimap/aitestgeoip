# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Config do
  describe '.geoip_db_path' do
    it 'uses the value from ENV if set' do
      allow(ENV).to receive(:[]).with('GEOIP_DB_PATH').and_return('/custom/path/to/db.mmdb')
      expect(described_class.geoip_db_path).to eq('/custom/path/to/db.mmdb')
    end

    it 'uses the default value if ENV is not set' do
      allow(ENV).to receive(:[]).with('GEOIP_DB_PATH').and_return(nil)
      expect(described_class.geoip_db_path).to eq('./app/bin/GeoLite2-City.mmdb')
    end
  end

  describe '.rack_env' do
    it 'uses the value from ENV if set' do
      allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production')
      expect(described_class.rack_env).to eq('production')
    end

    it 'uses the default value if ENV is not set' do
      allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil)
      expect(described_class.rack_env).to eq('development')
    end
  end
end
