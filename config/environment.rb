# frozen_string_literal: true

require_relative 'config'
ENV['RACK_ENV'] ||= Config.rack_env

require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV', nil))

require_all 'app'
