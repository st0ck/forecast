module Api
  module V1
    module Meteo
      # Handles requests for fetching the daily forecast for a given geolocation.
      class ForecastController < ApplicationController
        # Handles the request to get the weather for the specified geolocation and date.
        def create
          with_error_handling do
            return handle_general_error(error: geolocation.errors.full_messages.to_sentence) unless geolocation.valid?

            service = ::Meteo::ForecastService.new(
              search_params[:lat],
              search_params[:lon],
              Rails.application.config.redis_pool
            )

            weather = service.perform

            response.set_header('X-Cache-Hit', weather.cache_hit ? 'true' : 'false')
            response.set_header('X-Cache-Age', weather.cache_age.to_s) if weather.cache_hit

            if weather.data.nil? || weather.error
              handle_general_error(error: weather.error || 'Service unavailable', status_code: :internal_server_error)
            else
              handle_success_response(data: weather.data)
            end
          end
        end

        private

        # Returns a Geo::Location object with validated latitude and longitude.
        # @return [Geo::Location] a location object initialized with the provided lat and lon from search_params.
        def geolocation
          @geolocation ||= ::Geo::Location.new(lat: search_params[:lat], lon: search_params[:lon])
        end

        def search_params
          params.require(:forecast).permit(:lat, :lon).tap do |parameters|
            raise ActionController::ParameterMissing.new('lat') unless parameters[:lat].present?
            raise ActionController::ParameterMissing.new('lon') unless parameters[:lon].present?
          end
        end
      end
    end
  end
end
