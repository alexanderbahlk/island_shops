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

# Load and create shop item categories, subcategories, and types
xml_file_path = Rails.root.join("db", "seeds", "shop_item_categories.xml")

if File.exist?(xml_file_path)
  puts "Loading shop item categories, subcategories, and types from XML..."

  xml_content = File.read(xml_file_path)
  doc = Nokogiri::XML(xml_content)

  doc.xpath("//category").each do |category_node|
    category_title = category_node.xpath("title").text

    # Create or find category
    category = ShopItemCategory.find_or_create_by!(title: category_title)
    puts "Created/found category: #{category.title}"

    # Create subcategories and types
    category_node.xpath("subcategories/subcategory").each do |subcategory_node|
      subcategory_title = subcategory_node.xpath("title").text

      # Skip if subcategory doesn't have a title
      next if subcategory_title.blank?

      subcategory = ShopItemSubCategory.find_or_create_by!(
        title: subcategory_title,
        shop_item_category: category,
      )
      puts "  - Created/found subcategory: #{subcategory.title}"

      # Create types for this subcategory
      subcategory_node.xpath("types/type").each do |type_node|
        type_title = type_node.text

        # Skip if type doesn't have a title
        next if type_title.blank?

        # Find or create the type and associate it with the subcategory
        shop_item_type = subcategory.add_type(type_title)

        puts "    - Created/found type: #{shop_item_type.title}"
      end
    end
  end

  puts "Finished loading categories, subcategories, and types."
else
  puts "Warning: shop_item_categories.xml not found at #{xml_file_path}"
end

# Print summary statistics
puts "\n=== SUMMARY ==="
puts "Categories: #{ShopItemCategory.count}"
puts "Subcategories: #{ShopItemSubCategory.count}"
puts "Types: #{ShopItemType.count}"
puts "==============="
