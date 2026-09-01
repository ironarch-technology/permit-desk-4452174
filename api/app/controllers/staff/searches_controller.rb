module Staff
  # Front-counter search across the whole corpus. The counter needs this to answer
  # "what is happening with my permit" calls without an application reference.
  class SearchesController < ApplicationController
    include Authentication

    PER_PAGE = 50

    def index
      scope = PermitApplication.includes(:parcel).order(created_at: :desc)

      scope = scope.where(state: params[:state]) if params[:state].present?
      scope = scope.where('applicant_name ILIKE ?', "%#{PermitApplication.sanitize_sql_like(params[:applicant_name])}%") if params[:applicant_name].present?
      scope = scope.joins(:parcel).where('parcels.street_address ILIKE ?', "%#{Parcel.sanitize_sql_like(params[:parcel])}%") if params[:parcel].present?
      scope = scope.where('permit_applications.created_at >= ?', params[:from]) if params[:from].present?
      scope = scope.where('permit_applications.created_at <= ?', params[:to]) if params[:to].present?

      results = scope.limit(PER_PAGE).offset(params[:offset].to_i)

      render json: {
        count: results.size,
        results: results.map { |application| ApplicationSerializer.new(application).staff_row }
      }
    end
  end
end
