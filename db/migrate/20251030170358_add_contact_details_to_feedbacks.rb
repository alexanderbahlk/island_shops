class AddContactDetailsToFeedbacks < ActiveRecord::Migration[7.1]
  def change
    add_column :feedbacks, :contact_details, :string
  end
end
