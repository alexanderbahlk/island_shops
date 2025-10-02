namespace :migrate do
  desc "Migrate shop string data to Shop model"
  task shop_data: :environment do
    ShopItem.distinct.pluck(:shop).each do |shop_name|
      next if shop_name.blank?

      location = Location.find_or_create_by!(title: shop_name)
      ShopItem.where(shop: shop_name).update_all(location_id: location.id)
    end

    puts "Migration complete!"
  end
end
