namespace :migrate do
  desc "Migrate shop string data to Shop model"
  #rails migrate:shopping_list_users
  task shopping_list_users: :environment do
    ShoppingList.find_each do |shopping_list|
      if shopping_list.user.present?
        shopping_list.users << shopping_list.user unless shopping_list.users.include?(shopping_list.user)
        puts "Migrated ShoppingList ID #{shopping_list.id} to have User ID #{shopping_list.user.id}"
      else
        puts "ShoppingList ID #{shopping_list.id} has no associated user."
      end
    end

    puts "Migration complete!"
  end
end
