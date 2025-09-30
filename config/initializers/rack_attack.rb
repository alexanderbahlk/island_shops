class Rack::Attack
  # Throttle requests by app_hash (X-SECURE-APP-USER-HASH header)
  throttle("requests by app_hash", limit: 30, period: 1.minutes) do |req|
    req.env["HTTP_X_SECURE_APP_USER_HASH"]
  end

  # Blocklist specific app_hashes (optional)
  #blocklist('block abusive app_hash') do |req|
  #  # Example: Block a specific app_hash
  #  %w[abusive_hash_1 abusive_hash_2].include?(req.headers["X-SECURE-APP-USER-HASH"])
  #end

  # Custom response for throttled requests
  #self.throttled_response = lambda do |_env|
  #  [429, { "Content-Type" => "application/json" }, [{ error: "Rate limit exceeded. Try again later." }.to_json]]
  #end
end
