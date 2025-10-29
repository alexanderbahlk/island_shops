class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true # Associates feedback with a user
      t.text :content, null: false                      # Feedback content
      t.timestamps                                      # Adds created_at and updated_at
    end
  end
end
