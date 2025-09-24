class ProductSearch
  include PgSearchChecker

  SIMILARITY_THRESHOLD = 0.3

  attr_reader :query, :limit

  def initialize(query: false, limit: 5)
    @query = query&.strip
    @limit = limit
  end

  def results
    return [] if query.blank? || query.length < 2

    categories = find_similar_categories
    Rails.logger.info "ProductSearch: Found #{categories.size} similar categories for query '#{query}'"
    categories
  end

  private

  def find_similar_categories
    Rails.cache.fetch("product_search/#{query}/#{limit}", expires_in: 5.minutes) do
      return [] unless pg_trgm_available?

      sanitized_query = ActiveRecord::Base.connection.quote(query.downcase)
      sql = <<~SQL
        WITH ranked_categories AS (
          SELECT categories.uuid, categories.title,
                 GREATEST(
                   similarity(categories.title, #{sanitized_query}),
                   similarity(categories.path, #{sanitized_query}),
                   COALESCE((
                     SELECT MAX(similarity(syn, #{sanitized_query}))
                     FROM unnest(categories.synonyms) AS syn
                   ), 0)
                 ) as sim_score
          FROM categories
          WHERE category_type = #{Category.category_types[:product]}
            AND (
              similarity(categories.title, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
              OR similarity(categories.path, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
              OR EXISTS (
                SELECT 1 FROM unnest(categories.synonyms) AS syn
                WHERE similarity(syn, #{sanitized_query}) > #{SIMILARITY_THRESHOLD}
              )
            )
        )
        SELECT * FROM ranked_categories
        ORDER BY sim_score DESC
        LIMIT #{limit.to_i}
      SQL

      # Directly map the SQL results to the desired structure and sort by title
      ActiveRecord::Base.connection.exec_query(sql).map do |result|
        { uuid: result["uuid"], title: result["title"] }
      end.sort_by { |category| category[:title] }
    end
  end
end
