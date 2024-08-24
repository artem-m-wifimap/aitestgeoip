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
      let(:mock_db) { instance_double(MaxMindDB::Client) }

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
    let(:ip) { '79.101.216.65' }
    let(:db) { instance_double(MaxMindDB::Client) }
    let(:result) do
      instance_double(MaxMindDB::Result,
                      found?: true)
    end

    before do
      allow(described_class).to receive(:db).and_return(db)
      allow(db).to receive(:lookup).with(ip).and_return(result)
    end

    context 'when the IP is found' do
      it 'returns a MaxMindDB::Result object' do
        expect(described_class.lookup(ip)).to eq(result)
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

    context 'when the IP is invalid' do
      let(:invalid_ip) { 'invalid_ip' }

      it 'raises an InvalidIP error' do
        expect do
          described_class.lookup(invalid_ip)
        end.to raise_error(GeoIPError::InvalidIP, 'Invalid IP address')
      end
    end
  end
end
