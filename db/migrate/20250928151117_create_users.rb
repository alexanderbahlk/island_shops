class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :app_hash

      t.timestamps
    end
  end
end
