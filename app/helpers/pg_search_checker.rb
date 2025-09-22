module PgSearchChecker
  def pg_trgm_available?
    begin
      result = ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm'")
      result.any?
    rescue => e
      Rails.logger.warn "pg_trgm extension check failed: #{e.message}"
      false
    end
  end
end
