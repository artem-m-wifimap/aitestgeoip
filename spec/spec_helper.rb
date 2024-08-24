# frozen_string_literal: true

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
