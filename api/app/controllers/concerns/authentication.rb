module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    header = request.headers['Authorization'].to_s
    token = header.start_with?('Bearer ') ? header.split(' ', 2).last : nil
    return render_unauthorized if token.blank?

    payload = TokenCodec.decode(token)
    @current_account = Account.find_by(id: payload['account_id'])
    render_unauthorized if @current_account.nil?
  rescue TokenCodec::InvalidToken
    render_unauthorized
  end

  def current_account
    @current_account
  end

  def require_technician!
    return if current_account&.technician?

    render json: { error: 'staff role required' }, status: :forbidden
  end

  def render_unauthorized
    render json: { error: 'unauthorized' }, status: :unauthorized
  end
end
