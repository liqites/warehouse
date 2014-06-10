require 'rack/oauth2'

module SyncAPIGuard
  extend ActiveSupport::Concern

  included do |base|
    use Rack::OAuth2::Server::Resource::Bearer, 'Sync API' do |request|
      request.access_token
    end
    helpers HelperMethods
    install_error_responders(base)
  end

# Helper Methods for Grape Endpoint
  module HelperMethods
    def guard!
      guard_by_token
    end

    private
    def guard_by_token
      token_string = get_token_string
      #raise BasicAuthError unless  ApiToken.find_by_token(token_string)
      raise BasicAuthError unless  '3dcba17f596969a676bfdd90b5425c703f983acf7306760e1057c95afe9f17b1d'==token_string
    end

    def get_token_string
      request.env[Rack::OAuth2::Server::Resource::ACCESS_TOKEN]
    end
  end

  module ClassMethods
    def guard_all!
      before do
        guard!
      end
    end

    private
    def install_error_responders(base)
      error_classes = [BasicAuthError]
      base.send :rescue_from, *error_classes, oauth2_bearer_token_error_handler
    end

    def oauth2_bearer_token_error_handler
      Proc.new { |e|
        response = case e
                     when BasicAuthError
                       Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                           :invalid_token,
                           'Invalid Token.')
                   end
        response.finish
      }
    end
  end
  class BasicAuthError<StandardError;
  end
end