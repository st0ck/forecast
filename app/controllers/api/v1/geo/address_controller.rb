module Api
  module V1
    module Geo
      class AddressController < ApplicationController
        def index
          with_error_handling do
            options = { session_id: search_params[:session_id] }
            service = ::Geo::AddressLookupService.new(query: search_params[:q], options: options)

            address_lookup_result = service.search

            if address_lookup_result.error
              handle_general_error(error: address_lookup_result.error, status_code: :internal_server_error)
            else
              handle_success_response(data: address_lookup_result.data)
            end
          end
        end

        def search_params
          params.permit(:q, :session_id).tap do |parameters|
            raise ActionController::ParameterMissing.new('q') unless parameters[:q].present?
            raise ActionController::ParameterMissing.new('session_id') unless parameters[:session_id].present?
          end
        end
      end
    end
  end
end
