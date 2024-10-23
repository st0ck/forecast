module Geo
  module Integrations
    # Implements geosearch functionality using the Mapbox Geocoding API to fetch address details.
    class MapboxAddressLookup < BaseAddressLookup
      BASE_URL = 'https://api.mapbox.com/geocoding/v5/mapbox.places'.freeze

      # @param request_handler [RequestHandler] the request handler for making requests.
      # @param session_token [String, nil] the session ID to track the request (optional).
      def initialize(request_handler, session_token = nil)
        @request_handler = request_handler
        @session_token = session_token
      end

      # Fetches addresses using the Mapbox API.
      # @param query [String] the partial address to search for.
      # @return [Array<Address>] the list of found addresses.
      def fetch(query)
        uri = build_uri(query)
        params = build_params(@session_token)
        response = @request_handler.make_request(uri, params: params, headers: build_headers)
        parse_response(response)
      end

      private

      # Builds the params for the Mapbox API request.
      # @param session_token [String, nil] the session ID to track the request (optional).
      # @return [Hash] parameters for the API request.
      def build_params(session_token = nil)
        base_params = { access_token: ENV['MAPBOX_ACCESS_TOKEN'] }
        base_params[:session_token] = session_token if session_token
        base_params
      end

      # Builds the URI for the Mapbox API request.
      # @param query [String] the partial address to search for.
      # @return [URI] the URI for the API request.
      def build_uri(query)
        uri = "#{BASE_URL}/#{URI.encode_www_form_component(query)}.json"
        URI(uri)
      end

      # Builds the headers
      # @return [Hash] the headers for the API request.
      def build_headers
        @headers ||= { Accept: 'application/json' }
      end

      # Parses the response from the Mapbox API.
      # @param response [Net::HTTPResponse] the HTTP response.
      # @return [Array<Address>] the list of found addresses.
      def parse_response(response)
        data = JSON.parse(response.body)

        data['features'].map do |feature|
          Address.new(
            name: feature['text'],
            address: feature['place_name'],
            latitude: feature['geometry']['coordinates'][1],
            longitude: feature['geometry']['coordinates'][0],
            country: feature['context']&.find { |c| c['id'].start_with?('country') }&.dig('text'),
            city: feature['context']&.find { |c| c['id'].start_with?('place') }&.dig('text'),
            postcode: feature['context']&.find { |c| c['id'].start_with?('postcode') }&.dig('text')
          )
        end
      end
    end
  end
end
