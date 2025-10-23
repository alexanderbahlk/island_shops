require "test_helper"

class Places::FuzzyFindPlaceByLatitudeLongitudeServiceTest < ActiveSupport::TestCase
  setup do
  end

  test "should find a place at exact coordinates" do
    place_params_with_coordinates = {
      title: "Coconutwater truck",
      location: "3F85+X7J, Oistins, Christ Church",
      latitude: 13.096200,
      longitude: -59.535900,
    }
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(
      place_params: place_params_with_coordinates,
    )
    result = service.call
    place_with_coordinates = places(:place_four) # Place with latitude and longitude
    assert_equal place_with_coordinates, result, "Expected to find the place at exact coordinates"
  end

  test "should find places within a radius" do
    place_params_with_coordinates = {
      title: "Coconutwater truck",
      location: "3F85+X7J, Oistins, Christ Church",
      latitude: 13.096100,
      longitude: -59.535800,
    }
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(
      place_params: place_params_with_coordinates,
    )
    result = service.call
    place_with_coordinates = places(:place_four)
    assert_equal place_with_coordinates, result, "Expected to find the place within the radius"
  end

  test "should find a place at exact coordinates with slightly different title" do
    place_params_with_coordinates = {
      title: "Coconut water guy",
      location: "3F85+X7J, Oistins, Christ Church",
      latitude: 13.096200,
      longitude: -59.535900,
    }
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(
      place_params: place_params_with_coordinates,
    )
    result = service.call
    place_with_coordinates = places(:place_four) # Place with latitude and longitude
    assert_equal place_with_coordinates, result, "Expected to find the place at exact coordinates"
  end

  test "should return nil when no places are found within the radius" do
    place_params_without_coordinates = {
      title: "Banana Stand",
      location: "3F85+X7J, Oistins, Christ Church",
    }
    service = Places::FuzzyFindPlaceByLatitudeLongitudeService.new(
      place_params: place_params_without_coordinates,
    )
    result = service.call

    assert_nil result, "Expected no places to be found"
  end
end
