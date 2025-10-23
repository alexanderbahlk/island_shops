class Places::FuzzyFindPlacesByTitleService
  attr_reader :place_title, :errors

  def initialize(place_title:)
    @place_title = place_title
    @errors = []
  end

  def call
    return nil if place_title.blank?

    sanitized_place_title = ActiveRecord::Base.connection.quote(place_title)

    similarity_threshold = 0.8 # Adjust this value between 0.0 and 1.0

    # Ensure the pg_trgm extension is enabled
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    cache_key = "fuzzy_match_place_by_title/#{place_title}_#{similarity_threshold}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do

      # Perform a fuzzy search using similarity
      sql = <<~SQL
              SELECT  places.id, 
                      GREATEST(
                        similarity(places.title, #{sanitized_place_title})
                    ) as sim_score
        FROM places
        WHERE GREATEST(
                similarity(places.title, #{sanitized_place_title})
              ) >= #{similarity_threshold}
        ORDER BY sim_score DESC
        LIMIT 10
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)
      places = results.map { |row| Place.find(row["id"]) }
      places
    end
  end
end
