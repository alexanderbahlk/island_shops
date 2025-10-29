class AddTutorialStepToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :tutorial_step, :integer, default: 0, null: false
  end
end
