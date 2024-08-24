# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeoIPResultDecorator do
  subject(:decorator) { described_class.new(ip, mock_result) }

  let(:ip) { '8.8.8.8' }
  let(:mock_result) do
    double(
      'MaxMindDB::Result',
      city: double('City', name: 'Mountain View', geoname_id: 5_375_480),
      continent: double('Continent', name: 'North America', code: 'NA', geoname_id: 6_255_149),
      country: double('Country', name: 'United States', iso_code: 'US', geoname_id: 6_252_001,
                                 is_in_european_union: false),
      location: double('Location', time_zone: 'America/Los_Angeles', latitude: 37.4223, longitude: -122.0848,
                                   metro_code: 807, accuracy_radius: 1000),
      registered_country: double('RegisteredCountry', name: 'United States', iso_code: 'US', geoname_id: 6_252_001,
                                                      is_in_european_union: false),
      subdivisions: [double('Subdivision', name: 'California', iso_code: 'CA', geoname_id: 5_332_921)]
    )
  end

  describe '#decorate' do
    it 'returns a hash with all the expected keys' do
      decorated = decorator.decorate
      expect(decorated.keys).to contain_exactly(:client_ip, :city, :continent, :country, :location,
                                                :registered_country, :subdivisions)
    end

    it 'correctly decorates the client IP' do
      expect(decorator.decorate[:client_ip]).to eq(ip)
    end

    it 'correctly decorates the city information' do
      city = decorator.decorate[:city]
      expect(city[:names]['en']).to eq('Mountain View')
      expect(city[:geoname_id]).to eq(5_375_480)
    end

    it 'correctly decorates the continent information' do
      continent = decorator.decorate[:continent]
      expect(continent[:names]['en']).to eq('North America')
      expect(continent[:code]).to eq('NA')
      expect(continent[:geoname_id]).to eq(6_255_149)
    end

    it 'correctly decorates the country information' do
      country = decorator.decorate[:country]
      expect(country[:names]['en']).to eq('United States')
      expect(country[:iso_code]).to eq('US')
      expect(country[:geoname_id]).to eq(6_252_001)
      expect(country[:is_in_european_union]).to be false
    end

    it 'correctly decorates the location information' do
      location = decorator.decorate[:location]
      expect(location).to include(
        time_zone: 'America/Los_Angeles',
        latitude: 37.4223,
        longitude: -122.0848
      )
    end

    it 'includes metro code and accuracy radius in location information' do
      location = decorator.decorate[:location]
      expect(location).to include(
        metro_code: 807,
        accuracy_radius: 1000
      )
    end

    it 'correctly decorates the registered country information' do
      registered_country = decorator.decorate[:registered_country]
      expect(registered_country[:names]['en']).to eq('United States')
      expect(registered_country[:iso_code]).to eq('US')
      expect(registered_country[:geoname_id]).to eq(6_252_001)
      expect(registered_country[:is_in_european_union]).to be false
    end

    it 'correctly decorates the subdivisions information' do
      subdivisions = decorator.decorate[:subdivisions]
      expect(subdivisions).to be_an(Array)
      expect(subdivisions.first[:names]['en']).to eq('California')
      expect(subdivisions.first[:iso_code]).to eq('CA')
      expect(subdivisions.first[:geoname_id]).to eq(5_332_921)
    end
  end
end
