module JsonResponseHelper
  extend ActiveSupport::Concern

  # Handles missing parameter errors
  # @param exception [Exception] the raised exception with details about the missing parameter
  def handle_missing_parameter_request(exception)
    handle_general_error(error: exception.message, status_code: :bad_request)
  end

  # Handles internal server exceptions
  # If in development mode, includes the original error message
  # @param exception [Exception] the raised exception to handle
  def handle_internal_server_error(exception)
    message = if Rails.env.development?
      [exception.message] + exception.backtrace.select { |path| path.match?(/\/app\//) }
    else
      i18n(:internal_error)
    end

    handle_general_error(error: message, status_code: :internal_server_error)
  end

  # Handles too many requests error (429 Too Many Requests)
  # Sets the "Retry-After" header and returns an appropriate error message
  # @param exception [Exception] the raised exception containing retry details
  def handle_too_many_requests_error(exception)
    response.set_header('Retry-After', exception.retry_after)
    message = i18n(:too_many_requests, retry_after: exception.retry_after)
    handle_general_error(error: message, status_code: :too_many_requests)
  end

  # Handles successful responses
  # @param data [Hash] the data to include in the response
  # @param status [Symbol] the HTTP status to return (default: :ok)
  def handle_success_response(data:, status: :ok)
    render(
      json: {
        data: data,
        errors: nil
      },
      status: status
    )
  end

  # Handles general errors with a custom error message and status code
  # @param error [String] the error message to include in the response
  # @param status_code [Symbol] the HTTP status code to return (default: :bad_request)
  def handle_general_error(error: i18n(:bad_request), status_code: :bad_request)
    render(
      json: {
        data: nil,
        errors: [ {
          code: status_code,
          message: error
        } ]
      },
      status: status_code
    )
  end

  # Executes the given block with error handling for common exceptions.
  # Handles specific errors such as TooManyRequests and ParameterMissing, providing appropriate responses.
  # @yield the block of code to be executed with error handling.
  # @raise [Errors::TooManyRequests, ActionController::ParameterMissing, StandardError] specific error handlers for each type of exception.
  def with_error_handling
    yield
  rescue Errors::TooManyRequests => ex
    handle_too_many_requests_error(ex)
  rescue ActionController::ParameterMissing => ex
    handle_missing_parameter_request(ex)
  rescue StandardError => ex
    handle_internal_server_error(ex)
  end

  private

  def i18n(key, **options)
    I18n.t(key, scope: 'json_response_helper', **options)
  end
end
