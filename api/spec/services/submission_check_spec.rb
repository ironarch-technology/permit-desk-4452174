require 'rails_helper'

RSpec.describe SubmissionCheck do
  let(:account) do
    Account.create!(email: 'check@example.com', full_name: 'Check Applicant', password: 'spec-password')
  end

  let!(:parcel) do
    Parcel.create!(apn: '000-000-002', street_address: '9 Check Street', postal_code: '19714',
                   district: 'north', zone_code: 'R-2')
  end

  def build_application(attrs = {})
    account.permit_applications.create!({
      state: 'draft',
      work_type: 'reroof',
      scope_of_work: 'Replace shingles on the south elevation',
      declared_valuation_cents: 20_000_00,
      applicant_name: 'Check Applicant',
      applicant_email: 'check@example.com'
    }.merge(attrs))
  end

  it 'passes a complete residential application' do
    result = described_class.new.call(build_application, '9 Check Street')
    expect(result).to be_ok
    expect(result.parcel).to eq(parcel)
  end

  it 'rejects an address that is not a Mountport parcel' do
    result = described_class.new.call(build_application, '400 Nowhere Road')
    expect(result.errors).to include(/does not match a Mountport parcel/)
  end

  it 'rejects a valuation above the ceiling for the work type' do
    application = build_application(declared_valuation_cents: 900_000_00)
    result = described_class.new.call(application, '9 Check Street')
    expect(result.errors).to include(/outside the range allowed/)
  end

  it 'rejects a zero valuation' do
    application = build_application(declared_valuation_cents: 0)
    result = described_class.new.call(application, '9 Check Street')
    expect(result.errors).to include(/positive amount/)
  end

  it 'rejects a contractor licence that has already lapsed' do
    application = build_application(contractor_license_number: 'DE-CON-000001',
                                    contractor_license_expires_on: Date.current - 1)
    result = described_class.new.call(application, '9 Check Street')
    expect(result.errors).to include(/licence has expired/)
  end

  it 'reports every missing required field at once' do
    application = build_application(applicant_name: nil, scope_of_work: nil)
    result = described_class.new.call(application, '9 Check Street')
    expect(result.errors.length).to be >= 2
  end
end
