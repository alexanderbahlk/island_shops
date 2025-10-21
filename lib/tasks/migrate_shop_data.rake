namespace :migrate do
  desc "Migrate shop string data to Shop model"
  #rails migrate:shop_data
  task shop_data: :environment do
    ShopItem.distinct.pluck(:shop).each do |shop_name|
      next if shop_name.blank?

      place = Place.find_or_create_by!(title: shop_name)
      ShopItem.where(shop: shop_name).update_all(place_id: place.id)
    end

    puts "Migration complete!"
  end
end
