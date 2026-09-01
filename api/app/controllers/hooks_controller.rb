# Callbacks from the city services. These land on the internal network only; the
# portal's public routes are the ones behind the reverse proxy.
class HooksController < ApplicationController
  def zoning
    application = PermitApplication.find_by(reference: params[:reference])
    return head :not_found if application.nil?
    return head :accepted if application.terminal?

    Zoning::ApplyResult.new.call(application, {
      'outcome' => params[:outcome],
      'reason' => params[:reason]
    })

    head :accepted
  end

  def cashiering
    application = PermitApplication.find_by(reference: params[:reference])
    return head :not_found if application.nil?
    return head :accepted if application.terminal?

    if params[:status] == 'captured'
      Issuance.new.call(application, reason: "payment #{params[:payment_reference]}")
    end

    head :accepted
  end
end
