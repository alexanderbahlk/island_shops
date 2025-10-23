class Places::FuzzyFindPlaceByLatitudeLongitudeService
  attr_reader :latitude, :longitude, :title, :errors

  def initialize(place_params:)
    @place_params = place_params
    @latitude = @place_params[:latitude]
    @longitude = @place_params[:longitude]
    @title = @place_params[:title]
    @errors = []
  end

  def call
    return nil if latitude.blank? || longitude.blank? || title.blank?

    radius_in_meters = 20 # 10 meters radius

    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS cube")
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS earthdistance")
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    cache_key = "fuzzy_match_place_by_coordinates/#{latitude}_#{longitude}"
    results = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      sql = <<~SQL
        SELECT *, earth_distance(ll_to_earth(places.latitude, places.longitude), ll_to_earth(#{latitude}, #{longitude})) AS distance
        FROM places
        WHERE places.latitude IS NOT NULL AND places.longitude IS NOT NULL
        AND earth_distance(ll_to_earth(places.latitude, places.longitude), ll_to_earth(#{latitude}, #{longitude})) <= #{radius_in_meters}
        ORDER BY distance ASC
        LIMIT 10
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)

      return nil if results.empty?

      results
    end

    return nil if results.empty?

    similarity_threshold = 0.4 # Adjust this value between 0.0 and 1.0

    cache_key = "fuzzy_match_place_by_coordinates/#{latitude}_#{longitude}_#{title}_#{similarity_threshold}"
    sanitized_place_title = ActiveRecord::Base.connection.quote(title)
    closest_places = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      # Find the place with the closest title using similarity
      # Perform a fuzzy search using similarity
      results_ids = results.map { |row| row["id"] }.join(", ")
      sql = <<~SQL
              SELECT  places.id, 
                      GREATEST(
                        similarity(places.title, #{sanitized_place_title})
                    ) as sim_score
        FROM places
        WHERE places.id IN (#{results_ids})
        AND GREATEST(
                similarity(places.title, #{sanitized_place_title})
              ) >= #{similarity_threshold}
        ORDER BY sim_score DESC
        LIMIT 1
      SQL

      results = ActiveRecord::Base.connection.exec_query(sql)
      places = results.map { |row| Place.find(row["id"]) }
      places
    end
    return nil if closest_places.empty?
    Place.find(closest_places.first["id"])
  end
end
