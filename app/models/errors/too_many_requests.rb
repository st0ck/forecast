module Errors
  class TooManyRequests < StandardError
    attr_reader :retry_after

    def initialize(retry_after: 1)
      @retry_after = retry_after
      message = I18n.t(:too_many_requests, scope: 'errors', retry_after: exception.retry_after)
      super(message)
    end
  end
end
