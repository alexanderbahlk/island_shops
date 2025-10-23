class Places::FuzzyFindPlaceByTitleLocationService
  attr_reader :location, :title, :errors

  def initialize(place_params:)
    @place_params = place_params
    @location = @place_params[:location]
    @title = @place_params[:title]
    @errors = []
  end

  def call
    return nil if title.blank? || location.blank?

    fuzzy_find_places_by_title_service = Places::FuzzyFindPlacesByTitleService.new(place_title: title)
    places = fuzzy_find_places_by_title_service.call
    if fuzzy_find_places_by_title_service.errors.any?
      @errors.concat(fuzzy_find_places_by_title_service.errors)
    end

    return nil if places.blank? || places.empty?

    fuzzy_find_places_by_ids_and_location_service = Places::FuzzyFindPlacesByIdsAndLocation.new(
      place_ids: places.map(&:id),
      location: location,
    )
    places = fuzzy_find_places_by_ids_and_location_service.call
    if fuzzy_find_places_by_ids_and_location_service.errors.any?
      @errors.concat(fuzzy_find_places_by_ids_and_location_service.errors)
    end

    return nil if places.blank? || places.empty?

    if places.any?
      places.first
    end
  end
end
