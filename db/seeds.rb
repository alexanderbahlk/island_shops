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

# Require the CategoryImporter
require_relative "seeds/category_importer"

# Only create the admin user if it doesn't already exist
if AdminUser.where(email: "admin@islandshop.com").blank?
  AdminUser.create!(email: "admin@islandshop.com", password: "1password#@", password_confirmation: "1password#@")
end
