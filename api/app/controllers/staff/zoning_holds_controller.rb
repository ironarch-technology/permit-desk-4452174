module Staff
  # A parcel with conflicting records comes back from zoning as indeterminate and a
  # technician decides it against the paper file.
  class ZoningHoldsController < ApplicationController
    include Authentication

    before_action :require_technician!

    def resolve
      application = PermitApplication.find_by!(reference: params[:id])

      unless application.state == 'zoning_hold'
        return render json: { error: 'application is not on a zoning hold' }, status: :conflict
      end

      target = params[:outcome] == 'pass' ? 'plan_review' : 'denied'

      unless Lifecycle.permitted?(application.state, target)
        return render json: { error: 'not a permitted resolution' }, status: :conflict
      end

      Lifecycle.apply!(
        application,
        to: target,
        actor: "technician:#{current_account.id}",
        source_system: 'permit-desk',
        reason: params[:notes]
      ) do
        next unless target == 'plan_review'

        Bus::Producer.publish(
          Bus::Topics::REVIEW_SUBMISSIONS,
          key: application.reference,
          payload: {
            reference: application.reference,
            cycle: application.review_cycle,
            work_type: application.work_type,
            scope_of_work: application.scope_of_work,
            valuation_cents: application.declared_valuation_cents
          }
        )
      end

      render json: ApplicationSerializer.new(application).detail
    end
  end
end
