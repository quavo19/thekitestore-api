# Geocoder configuration for reverse geocoding
# Uses coordinates (latitude/longitude) for reverse geocoding

Geocoder.configure(
  # Use a free geocoding service (Nominatim by default)
  # You can configure other services like Google, Mapbox, etc. if needed
  lookup: :nominatim,
  
  # Timeout for geocoding requests (in seconds)
  timeout: 5,
  
  # Use HTTPS
  use_https: true,
  
  # Language for results
  language: :en,
  
  # HTTP headers (Nominatim requires User-Agent per their usage policy)
  http_headers: {
    "User-Agent" => ENV.fetch("GEOCODER_USER_AGENT", "TheKiteStoreAPI/1.0")
  },
  
  # Cache configuration (optional - can use Redis, file, etc.)
  # cache: Redis.new,
  # cache_prefix: "geocoder:",
  
  # Rate limiting (requests per second)
  # Nominatim allows 1 request per second for free tier
  units: :km
)
