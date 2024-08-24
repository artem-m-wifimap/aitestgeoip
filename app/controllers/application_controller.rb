# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require_relative '../helpers/ip_helper'
require_relative '../errors/geoip_error'

class ApplicationController < Sinatra::Base
  include IPHelper

  configure do
    set :show_exceptions, false
  end

  error GeoIPError::InvalidIP do
    status 400
    json error: 'Invalid IP address provided'
  end

  error GeoIPError::IPNotFound do
    status 404
    json error: 'IP address not found in the database'
  end

  error GeoIPError::DatabaseError do
    status 500
    json error: 'Error accessing the GeoIP database'
  end

  error StandardError do
    status 500
    json error: 'An unexpected error occurred'
  end

  get '/geoip' do
    ip = params['ip'] || request_ip
    result = GeoIPService.lookup(ip)
    json result
  end
end
