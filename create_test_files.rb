#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
  puts "Created: #{path}"
end

# spec_helper.rb
spec_helper_content = <<~RUBY
  require 'rack/test'
  require 'rspec'

  ENV['RACK_ENV'] = 'test'

  require_relative '../config/environment'

  RSpec.configure do |config|
    config.include Rack::Test::Methods
  end

  def app
    ApplicationController
  end
RUBY

write_file('spec/spec_helper.rb', spec_helper_content)

# geoip_service_spec.rb
geoip_service_spec_content = <<~RUBY
  require 'spec_helper'

  RSpec.describe GeoIPService do
    describe '.load_database' do
      context 'when GEOIP_DB_PATH is not set' do
        before do
          allow(Config).to receive(:GEOIP_DB_PATH).and_return(nil)
        end

        it 'raises an error' do
          expect { GeoIPService.load_database }.to raise_error(RuntimeError, "GEOIP_DB_PATH is not set")
        end
      end

      context 'when the database file does not exist' do
        before do
          allow(Config).to receive(:GEOIP_DB_PATH).and_return('/non/existent/path')
          allow(File).to receive(:exist?).with('/non/existent/path').and_return(false)
        end

        it 'raises an error' do
          expect { GeoIPService.load_database }.to raise_error(RuntimeError, "GeoIP database file not found at /non/existent/path")
        end
      end

      context 'when the database file exists' do
        let(:db_path) { '/path/to/geoip.mmdb' }
        let(:mock_db) { instance_double(MaxMindDB) }

        before do
          allow(Config).to receive(:GEOIP_DB_PATH).and_return(db_path)
          allow(File).to receive(:exist?).with(db_path).and_return(true)
          allow(MaxMindDB).to receive(:new).with(db_path).and_return(mock_db)
        end

        it 'returns a MaxMindDB instance' do
          expect(GeoIPService.load_database).to eq(mock_db)
        end
      end
    end

    describe '.db' do
      it 'memoizes the database instance' do
        expect(GeoIPService).to receive(:load_database).once.and_return(double('MaxMindDB instance'))
        2.times { GeoIPService.db }
      end
    end

    describe '.lookup' do
      let(:ip) { '8.8.8.8' }
      let(:db) { instance_double(MaxMindDB) }
      let(:result) { instance_double(MaxMindDB::Result) }

      before do
        allow(GeoIPService).to receive(:db).and_return(db)
        allow(db).to receive(:lookup).with(ip).and_return(result)
      end

      context 'when the IP is found' do
        before do
          allow(result).to receive(:found?).and_return(true)
          allow(result).to receive_message_chain(:country, :name).and_return('United States')
          allow(result).to receive_message_chain(:country, :iso_code).and_return('US')
          allow(result).to receive_message_chain(:city, :name).and_return('Mountain View')
          allow(result).to receive_message_chain(:postal, :code).and_return('94043')
          allow(result).to receive_message_chain(:location, :latitude).and_return(37.4223)
          allow(result).to receive_message_chain(:location, :longitude).and_return(-122.0848)
          allow(result).to receive_message_chain(:location, :time_zone).and_return('America/Los_Angeles')
        end

        it 'returns a hash with geolocation data' do
          expected_result = {
            ip: ip,
            country: 'United States',
            country_code: 'US',
            city: 'Mountain View',
            postal_code: '94043',
            latitude: 37.4223,
            longitude: -122.0848,
            time_zone: 'America/Los_Angeles'
          }
          expect(GeoIPService.lookup(ip)).to eq(expected_result)
        end
      end

      context 'when the IP is not found' do
        before do
          allow(result).to receive(:found?).and_return(false)
        end

        it 'returns nil' do
          expect(GeoIPService.lookup(ip)).to be_nil
        end
      end
    end
  end
RUBY

write_file('spec/services/geoip_service_spec.rb', geoip_service_spec_content)

# application_controller_spec.rb
application_controller_spec_content = <<~RUBY
  require 'spec_helper'

  RSpec.describe ApplicationController do
    describe 'GET /geoip' do
      context 'when IP is provided' do
        let(:ip) { '8.8.8.8' }
        let(:geoip_result) do
          {
            ip: ip,
            country: 'United States',
            country_code: 'US',
            city: 'Mountain View',
            postal_code: '94043',
            latitude: 37.4223,
            longitude: -122.0848,
            time_zone: 'America/Los_Angeles'
          }
        end

        before do
          allow(GeoIPService).to receive(:lookup).with(ip).and_return(geoip_result)
        end

        it 'returns geolocation data for the provided IP' do
          get "/geoip?ip=\#{ip}"
          expect(last_response).to be_ok
          expect(JSON.parse(last_response.body)).to eq(geoip_result.transform_keys(&:to_s))
        end
      end

      context 'when IP is not provided' do
        let(:request_ip) { '192.168.1.1' }
        let(:geoip_result) do
          {
            ip: request_ip,
            country: 'United States',
            country_code: 'US',
            city: 'New York',
            postal_code: '10001',
            latitude: 40.7128,
            longitude: -74.0060,
            time_zone: 'America/New_York'
          }
        end

        before do
          allow_any_instance_of(ApplicationController).to receive(:request_ip).and_return(request_ip)
          allow(GeoIPService).to receive(:lookup).with(request_ip).and_return(geoip_result)
        end

        it 'returns geolocation data for the request IP' do
          get '/geoip'
          expect(last_response).to be_ok
          expect(JSON.parse(last_response.body)).to eq(geoip_result.transform_keys(&:to_s))
        end
      end

      context 'when IP is not found' do
        let(:ip) { '0.0.0.0' }

        before do
          allow(GeoIPService).to receive(:lookup).with(ip).and_return(nil)
        end

        it 'returns a 404 error' do
          get "/geoip?ip=\#{ip}"
          expect(last_response.status).to eq(404)
          expect(JSON.parse(last_response.body)).to eq({ 'error' => 'IP address not found or invalid' })
        end
      end

      context 'when an error occurs' do
        let(:ip) { '8.8.8.8' }

        before do
          allow(GeoIPService).to receive(:lookup).with(ip).and_raise(StandardError, 'Test error')
        end

        it 'returns a 500 error' do
          get "/geoip?ip=\#{ip}"
          expect(last_response.status).to eq(500)
          expect(JSON.parse(last_response.body)).to eq({ 'error' => 'An error occurred: Test error' })
        end
      end
    end
  end
RUBY

write_file('spec/controllers/application_controller_spec.rb', application_controller_spec_content)

# ip_helper_spec.rb
ip_helper_spec_content = <<~RUBY
  require 'spec_helper'

  RSpec.describe IPHelper do
    let(:helper) { Class.new { include IPHelper }.new }

    describe '#request_ip' do
      context 'when X-Forwarded-For header is present' do
        it 'returns the first IP from X-Forwarded-For' do
          env = { 'HTTP_X_FORWARDED_FOR' => '203.0.113.1, 198.51.100.2' }
          allow(helper).to receive(:env).and_return(env)
          expect(helper.request_ip).to eq('203.0.113.1')
        end
      end

      context 'when X-Forwarded-For header is not present' do
        it 'returns the REMOTE_ADDR' do
          env = { 'REMOTE_ADDR' => '192.0.2.1' }
          allow(helper).to receive(:env).and_return(env)
          expect(helper.request_ip).to eq('192.0.2.1')
        end
      end
    end
  end
RUBY

write_file('spec/helpers/ip_helper_spec.rb', ip_helper_spec_content)

# config_spec.rb
config_spec_content = <<~RUBY
  require 'spec_helper'

  RSpec.describe Config do
    describe 'GEOIP_DB_PATH' do
      it 'uses the value from ENV if set' do
        allow(ENV).to receive(:[]).with('GEOIP_DB_PATH').and_return('/custom/path/to/db.mmdb')
        expect(Config::GEOIP_DB_PATH).to eq('/custom/path/to/db.mmdb')
      end

      it 'uses the default value if ENV is not set' do
        allow(ENV).to receive(:[]).with('GEOIP_DB_PATH').and_return(nil)
        expect(Config::GEOIP_DB_PATH).to eq('./app/bin/GeoLite2-City.mmdb')
      end
    end

    describe 'RACK_ENV' do
      it 'uses the value from ENV if set' do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production')
        expect(Config::RACK_ENV).to eq('production')
      end

      it 'uses the default value if ENV is not set' do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil)
        expect(Config::RACK_ENV).to eq('development')
      end
    end
  end
RUBY

write_file('spec/config/config_spec.rb', config_spec_content)

puts 'All test files have been created successfully!'
