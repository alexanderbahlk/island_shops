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
    categories
  end

  private

  def find_similar_categories
    return [] unless pg_trgm_available?

    sanitized_query = ActiveRecord::Base.connection.quote(query.downcase)
    sql = <<~SQL
      SELECT categories.*,
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
      ORDER BY sim_score DESC
      LIMIT #{limit.to_i}
    SQL

    results = ActiveRecord::Base.connection.exec_query(sql)
    category_ids = results.map { |result| result["id"] }
    categories = Category.where(id: category_ids).includes(:parent)
    results.map do |result|
      category = categories.find { |c| c.id == result["id"].to_i }
      if category
        category.define_singleton_method(:sim_score) { result["sim_score"].to_f }
        category
      end
    end.compact
  end
end
