class Places::FuzzyFindPlacesByIdsAndLocation
  attr_reader :place_ids, :location, :errors

  def initialize(place_ids:, location:)
    @place_ids = place_ids
    @location = location
    @errors = []
  end

  def call
    return nil if place_ids.blank? || location.blank?

    sanitized_location = ActiveRecord::Base.connection.quote(location)

    similarity_threshold = 0.8 # Adjust this value between 0.0 and 1.0

    # Ensure the pg_trgm extension is enabled
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    joined_place_ids = place_ids.join(", ")
    cache_key = "fuzzy_match_places_by_ids_and_location/#{joined_place_ids}_#{location}_#{similarity_threshold}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do

      # Perform a fuzzy search using similarity
      sql = <<~SQL
              SELECT  places.id, 
                      GREATEST(
                        similarity(places.location, #{sanitized_location})
                    ) as sim_score
        FROM places
        WHERE places.id IN (#{joined_place_ids})
        AND GREATEST(
                similarity(places.location, #{sanitized_location})
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
