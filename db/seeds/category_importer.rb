require "nokogiri"

class CategoryImporter
  def self.import_from_xml(file_path)
    puts "🗑️  Clearing existing categories..."
    Category.destroy_all
    puts "✅ Cleared all categories"

    doc = Nokogiri::XML(File.open(file_path))
    puts "📄 Loaded XML file: #{file_path}"

    importer = new
    importer.process_category_container(doc.root, nil)

    # Print detailed summary
    puts "\n" + "=" * 50
    puts "📊 IMPORT SUMMARY"
    puts "=" * 50
    puts "Total Categories: #{Category.count}"
    puts "Root Categories: #{Category.where(parent_id: nil).count}"
    puts "Level 1 Categories: #{Category.where(category_type: :category).count}"
    puts "Level 2 Subcategories: #{Category.where(category_type: :subcategory).count}"
    puts "Level 3 Products: #{Category.where(category_type: :product).count}"

    puts "\n📂 HIERARCHY:"
    Category.roots.each do |root|
      print_hierarchy(root, 0)
    end

    puts "\n" + "=" * 50
  end

  # Process a <categories> container element
  def process_category_container(container_element, parent_category)
    return unless container_element

    # Find all direct <category> children of this container
    container_element.xpath("category").each_with_index do |category_element, index|
      process_single_category(category_element, parent_category, index)
    end
  end

  # Process a single <category> element
  def process_single_category(category_element, parent_category, sort_order)
    # Get the title - this is required
    title_element = category_element.at("title")
    return unless title_element

    title = title_element.text.strip
    return if title.blank?

    # Calculate expected depth for validation
    expected_depth = parent_category ? parent_category.depth + 1 : 0

    # Create the category
    puts "#{" " * (expected_depth * 2)}📁 Creating: #{title} (depth #{expected_depth})"

    begin
      category = Category.create!(
        title: title,
        parent: parent_category,
        sort_order: sort_order,
      )

      puts "#{" " * (expected_depth * 2)}   ✅ #{category.title} (#{category.category_type})"
    rescue => e
      puts "#{" " * (expected_depth * 2)}   ❌ Failed: #{e.message}"
      return
    end

    # Check for nested categories first
    nested_categories = category_element.at("categories")
    if nested_categories
      puts "#{" " * (expected_depth * 2)}   🔄 Processing subcategories..."
      process_category_container(nested_categories, category)
    end

    # Process types (products) - only if no nested categories
    types_container = category_element.at("types")
    if types_container && !nested_categories
      process_product_types(types_container, category)
    elsif types_container && nested_categories
      puts "#{" " * (expected_depth * 2)}   ⚠️  Ignoring types - category has subcategories"
    end
  end

  # Process <types> container - create product categories
  def process_product_types(types_container, parent_category)
    types = types_container.xpath("type")
    puts "#{" " * (parent_category.depth * 2)}   🛍️  Processing #{types.count} products..."

    types.each_with_index do |type_element, index|
      type_title = type_element.text.strip
      next if type_title.blank?

      # Check for duplicates within this parent
      if Category.exists?(title: type_title, parent: parent_category)
        puts "#{" " * (parent_category.depth * 2)}      ⚠️  SKIP: #{type_title} (duplicate)"
        next
      end

      begin
        product = Category.create!(
          title: type_title,
          parent: parent_category,
          sort_order: index,
        )
        puts "#{" " * (parent_category.depth * 2)}      ✅ #{product.title} (#{product.category_type})"
      rescue => e
        puts "#{" " * (parent_category.depth * 2)}      ❌ Failed: #{type_title} - #{e.message}"
      end
    end
  end

  private

  def self.print_hierarchy(category, indent_level)
    puts "#{"  " * indent_level}#{category.title} (#{category.category_type}) - #{category.children.count} children"

    # Only show first few children to avoid too much output
    children_to_show = category.children.limit(3)
    children_to_show.each do |child|
      print_hierarchy(child, indent_level + 1)
    end

    if category.children.count > 3
      puts "#{"  " * (indent_level + 1)}... and #{category.children.count - 3} more"
    end
  end
end
