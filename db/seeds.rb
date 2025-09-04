# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#
# Only create the admin user if it doesn't already exist
if AdminUser.where(email: "admin@islandshop.com").blank?
  AdminUser.create!(email: "admin@islandshop.com", password: "1password#@", password_confirmation: "1password#@")
end
# Load and create shop item categories and subcategories
xml_file_path = Rails.root.join("db", "seeds", "shop_item_categories.xml")

if File.exist?(xml_file_path)
  puts "Loading shop item categories from XML..."

  xml_content = File.read(xml_file_path)
  doc = Nokogiri::XML(xml_content)

  doc.xpath("//category").each do |category_node|
    category_title = category_node.xpath("title").text

    # Create or find category
    category = ShopItemCategory.find_or_create_by!(title: category_title)
    puts "Created/found category: #{category.title}"

    # Create subcategories
    category_node.xpath("subcategories/subcategory").each do |subcategory_node|
      subcategory_title = subcategory_node.text

      subcategory = ShopItemSubCategory.find_or_create_by!(
        title: subcategory_title,
        shop_item_category: category,
      )
      puts "  - Created/found subcategory: #{subcategory.title}"
    end
  end

  puts "Finished loading categories and subcategories."
else
  puts "Warning: shop_item_categories.xml not found at #{xml_file_path}"
end
