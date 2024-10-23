ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require_relative 'support/redis_test_helper'
require 'rails/test_help'
require 'active_support/all'
require 'minitest/autorun'
require 'mocha/minitest'
require 'minitest/reporters'

Minitest::Reporters.use!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
  end
end
