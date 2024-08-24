# frozen_string_literal: true

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

      it 'returns a successful response for the provided IP' do
        get "/geoip?ip=#{ip}"
        expect(last_response).to be_ok
      end

      it 'returns correct geolocation data for the provided IP' do
        get "/geoip?ip=#{ip}"
        expect(JSON.parse(last_response.body)).to eq(geoip_result.transform_keys(&:to_s))
      end
    end

    context 'when IP is not provided' do
      let(:request_ip) { '127.0.0.1' }
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
        allow(GeoIPService).to receive(:lookup).with(request_ip).and_return(geoip_result)
      end

      it 'returns a successful response for the request IP' do
        get '/geoip'
        expect(last_response).to be_ok
      end

      it 'returns correct geolocation data for the request IP' do
        get '/geoip'
        expect(JSON.parse(last_response.body)).to eq(geoip_result.transform_keys(&:to_s))
      end
    end

    context 'when IP is not found' do
      let(:ip) { '0.0.0.0' }

      before do
        allow(GeoIPService).to receive(:lookup).with(ip).and_raise(GeoIPError::IPNotFound)
      end

      it 'returns a 404 status for not found IP' do
        get "/geoip?ip=#{ip}"
        expect(last_response.status).to eq(404)
      end

      it 'returns correct error message for not found IP' do
        get "/geoip?ip=#{ip}"
        expect(JSON.parse(last_response.body)).to eq({ 'error' => 'IP address not found in the database' })
      end
    end

    context 'when an error occurs' do
      let(:ip) { '8.8.8.8' }

      before do
        allow(GeoIPService).to receive(:lookup).with(ip).and_raise(StandardError, 'Test error')
      end

      it 'returns a 500 status for errors' do
        get "/geoip?ip=#{ip}"
        expect(last_response.status).to eq(500)
      end

      it 'returns correct error message for errors' do
        get "/geoip?ip=#{ip}"
        expect(JSON.parse(last_response.body)).to eq({ 'error' => 'An unexpected error occurred' })
      end
    end
  end
end
