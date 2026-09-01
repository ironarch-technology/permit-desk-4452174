# Intake validation applied when a draft is submitted. Draft editing is deliberately
# permissive; everything the department needs is enforced here instead.
class SubmissionCheck
  REQUIRED = %i[work_type scope_of_work declared_valuation_cents applicant_name applicant_email].freeze

  Result = Struct.new(:errors, :parcel, keyword_init: true) do
    def ok?
      errors.empty?
    end
  end

  def call(application, address)
    errors = []

    REQUIRED.each do |field|
      errors << "#{field} is required" if application.public_send(field).blank?
    end

    parcel = application.parcel || Parcel.resolve(address)
    errors << 'parcel address does not match a Mountport parcel' if parcel.nil?

    errors.concat(valuation_errors(application))
    errors.concat(contractor_errors(application))

    Result.new(errors: errors, parcel: parcel)
  end

  private

  def valuation_errors(application)
    amount = application.declared_valuation_cents.to_i
    bounds = PermitApplication::WORK_TYPES[application.work_type]
    return ['work type is not recognised'] if bounds.nil?
    return ['declared valuation must be a positive amount'] if amount <= 0

    if amount < bounds[:min_cents] || amount > bounds[:max_cents]
      ["declared valuation is outside the range allowed for #{application.work_type}"]
    else
      []
    end
  end

  def contractor_errors(application)
    return [] if application.contractor_license_number.blank?

    expiry = application.contractor_license_expires_on
    return ['contractor licence expiry is required'] if expiry.blank?
    return ['contractor licence has expired'] if expiry <= Date.current

    []
  end
end
