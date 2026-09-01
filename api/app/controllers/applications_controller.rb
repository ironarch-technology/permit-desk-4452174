class ApplicationsController < ApplicationController
  include Authentication

  def index
    applications = current_account.permit_applications.order(created_at: :desc)
    render json: applications.map { |a| ApplicationSerializer.new(a).summary }
  end

  def show
    render json: ApplicationSerializer.new(find_own).detail
  end

  def create
    application = current_account.permit_applications.new(application_params)
    application.state = 'draft'
    application.parcel = Parcel.resolve(params[:parcel_address]) if params[:parcel_address].present?
    application.save!

    render json: ApplicationSerializer.new(application).detail, status: :created
  end

  def update
    application = find_own
    return render json: { error: 'only a draft can be edited' }, status: :conflict unless application.state == 'draft'

    application.parcel = Parcel.resolve(params[:parcel_address]) if params[:parcel_address].present?
    application.update!(application_params)

    render json: ApplicationSerializer.new(application).detail
  end

  def destroy
    application = find_own
    return render json: { error: 'only a draft can be deleted' }, status: :conflict unless application.state == 'draft'

    application.destroy!
    head :no_content
  end

  def submit
    application = find_own

    replay = replayed_submission(application)
    return render json: ApplicationSerializer.new(replay).detail if replay

    unless Lifecycle.permitted?(application.state, 'submitted')
      return render json: { error: "cannot submit from #{application.state}" }, status: :conflict
    end

    check = SubmissionCheck.new.call(application, params[:parcel_address])
    return render json: { error: check.errors }, status: :unprocessable_entity unless check.ok?

    application.update!(
      parcel: check.parcel,
      submission_key: params[:submission_key],
      submitted_at: Time.zone.now
    )

    Lifecycle.apply!(application, to: 'submitted', actor: actor_label, reason: 'submitted by applicant')
    dispatch_zoning(application)

    render json: ApplicationSerializer.new(application.reload).detail
  end

  def withdraw
    application = find_own

    unless Lifecycle.permitted?(application.state, 'withdrawn')
      return render json: { error: "cannot withdraw from #{application.state}" }, status: :conflict
    end

    Lifecycle.apply!(application, to: 'withdrawn', actor: actor_label, reason: params[:reason])
    render json: ApplicationSerializer.new(application).detail
  end

  private

  def find_own
    current_account.permit_applications.find_by!(reference: params[:id])
  end

  def actor_label
    "account:#{current_account.id}"
  end

  def replayed_submission(application)
    key = params[:submission_key]
    return application if application.state != 'draft' && application.submission_key.present? &&
                          application.submission_key == key
    return nil if key.blank?

    PermitApplication.where(submission_key: key).where.not(id: application.id).first
  end

  def dispatch_zoning(application)
    Lifecycle.apply!(application, to: 'zoning_check', actor: 'permit-desk', reason: 'zoning check dispatched')
    Zoning::Dispatch.new.call(application)
  end

  def application_params
    params.permit(
      :work_type, :scope_of_work, :declared_valuation_cents, :applicant_name,
      :applicant_email, :applicant_phone, :contractor_license_number,
      :contractor_license_expires_on
    )
  end
end
