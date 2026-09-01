class SessionsController < ApplicationController
  def create
    account = Account.find_by(email: params[:email].to_s.downcase)

    if account&.authenticate(params[:password])
      render json: {
        token: TokenCodec.encode(account_id: account.id, role: account.role),
        account: { id: account.id, name: account.full_name, role: account.role }
      }
    else
      render json: { error: 'invalid credentials' }, status: :unauthorized
    end
  end
end
