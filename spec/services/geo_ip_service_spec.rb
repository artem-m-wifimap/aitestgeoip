# frozen_string_literal: true

require 'spec_helper'
require 'maxminddb'

RSpec.describe GeoIPService do
  describe '.load_database' do
    context 'when GEOIP_DB_PATH is not set' do
      before do
        allow(Config).to receive(:geoip_db_path).and_return(nil)
      end

      it 'raises a DatabaseError' do
        expect { described_class.load_database }.to raise_error(GeoIPError::DatabaseError, 'GEOIP_DB_PATH is not set')
      end
    end

    context 'when the database file does not exist' do
      before do
        allow(Config).to receive(:geoip_db_path).and_return('/non/existent/path')
        allow(File).to receive(:exist?).with('/non/existent/path').and_return(false)
      end

      it 'raises a DatabaseError' do
        expect do
          described_class.load_database
        end.to raise_error(GeoIPError::DatabaseError, 'GeoIP database file not found at /non/existent/path')
      end
    end

    context 'when the database file exists' do
      let(:db_path) { '/path/to/geoip.mmdb' }
      let(:mock_db) { instance_double(MaxMindDB) }

      before do
        allow(Config).to receive(:geoip_db_path).and_return(db_path)
        allow(File).to receive(:exist?).with(db_path).and_return(true)
        allow(MaxMindDB).to receive(:new).with(db_path).and_return(mock_db)
      end

      it 'returns a MaxMindDB instance' do
        expect(described_class.load_database).to eq(mock_db)
      end
    end
  end

  describe '.db' do
    let(:db_instance) { instance_double(MaxMindDB::Client) }

    it 'loads the database instance once' do
      allow(described_class).to receive(:load_database).and_return(db_instance)
      described_class.db
      described_class.db
      expect(described_class).to have_received(:load_database).once
    end

    it 'returns the same database instance on multiple calls' do
      first_call = described_class.db
      second_call = described_class.db
      expect(first_call).to eq(second_call)
    end
  end

  describe '.lookup' do
    let(:ip) { '127.0.0.1' }
    let(:db) { instance_double(MaxMindDB::Client) }
    let(:result) do
      instance_double(MaxMindDB::Result,
                      found?: true,
                      city: instance_double(MaxMindDB::Result::NamedLocation, name: 'Mountain View'),
                      country: instance_double(MaxMindDB::Result::NamedLocation, name: 'United States', iso_code: 'US'),
                      postal: instance_double(MaxMindDB::Result::Postal, code: '94043'),
                      location: instance_double(MaxMindDB::Result::Location,
                                                latitude: 37.4223,
                                                longitude: -122.0848,
                                                time_zone: 'America/Los_Angeles'))
    end

    before do
      allow(described_class).to receive(:db).and_return(db)
      allow(db).to receive(:lookup).with(ip).and_return(result)
    end

    context 'when the IP is found' do
      it 'returns a hash with geolocation data' do
        expect(described_class.lookup(ip)).to be_a(Hash)
      end

      it 'includes the correct IP' do
        expect(described_class.lookup(ip)[:ip]).to eq(ip)
      end

      it 'includes the correct country name' do
        expect(described_class.lookup(ip)[:country]).to eq('United States')
      end

      it 'includes the correct country code' do
        expect(described_class.lookup(ip)[:country_code]).to eq('US')
      end

      it 'includes the correct city' do
        expect(described_class.lookup(ip)[:city]).to eq('Mountain View')
      end

      it 'includes the correct postal code' do
        expect(described_class.lookup(ip)[:postal_code]).to eq('94043')
      end

      it 'includes the correct latitude' do
        expect(described_class.lookup(ip)[:latitude]).to eq(37.4223)
      end

      it 'includes the correct longitude' do
        expect(described_class.lookup(ip)[:longitude]).to eq(-122.0848)
      end

      it 'includes the correct time zone' do
        expect(described_class.lookup(ip)[:time_zone]).to eq('America/Los_Angeles')
      end
    end

    context 'when the IP is not found' do
      let(:result) { instance_double(MaxMindDB::Result, found?: false) }

      it 'raises an IPNotFound error' do
        expect do
          described_class.lookup(ip)
        end.to raise_error(GeoIPError::IPNotFound, 'IP address not found in the database')
      end
    end
  end
end
