# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails'

require 'super_diff/rspec-rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
