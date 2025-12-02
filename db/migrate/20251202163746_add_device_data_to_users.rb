class AddDeviceDataToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :device_data, :jsonb
  end
end
