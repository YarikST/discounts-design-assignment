# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    sequence(:full_name) { |number| "Customer #{number}" }
    sequence(:email) { |number| "customer#{number}@example.com" }
  end
end
