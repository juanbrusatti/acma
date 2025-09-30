module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key
      
      private
      
      def authenticate_api_key
        api_key = request.headers['X-API-Key']
        @api_user = ApiKey.find_by(key: api_key)&.user
        
        unless @api_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end
