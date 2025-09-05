ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Ensure pg_trgm extension is available for tests
  def setup
    super
    ensure_pg_trgm_extension
  end

  private

  def ensure_pg_trgm_extension
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
  rescue => e
    # Ignore if extension already exists or can't be created
    Rails.logger.warn "Could not ensure pg_trgm extension: #{e.message}"
  end
end
