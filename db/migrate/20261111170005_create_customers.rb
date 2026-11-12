# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :full_name, null: false
      t.string :email

      t.timestamps
    end
  end
end
