class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
  rescue_from Clients::ServiceError, with: :upstream_unavailable

  private

  def not_found
    render json: { error: 'not found' }, status: :not_found
  end

  def unprocessable(exception)
    render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def upstream_unavailable(exception)
    Rails.logger.error("upstream error=#{exception.message}")
    render json: { error: 'a city service is not responding' }, status: :bad_gateway
  end
end
