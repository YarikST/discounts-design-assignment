# frozen_string_literal: true

class Customer < ApplicationRecord
  has_many :orders, dependent: :nullify

  validates :full_name, presence: true
end
