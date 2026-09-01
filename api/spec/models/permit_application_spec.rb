require 'rails_helper'

RSpec.describe PermitApplication do
  let(:account) do
    Account.create!(email: 'model@example.com', full_name: 'Model Applicant', password: 'spec-password')
  end

  it 'assigns a reference on creation' do
    application = account.permit_applications.create!(state: 'draft')
    expect(application.reference).to match(/\APA-\d{4}-[A-Z0-9]{6}\z/)
  end

  it 'knows which states are terminal' do
    expect(described_class.new(state: 'withdrawn')).to be_terminal
    expect(described_class.new(state: 'plan_review')).not_to be_terminal
  end

  it 'returns only the current cycle of correction items' do
    application = account.permit_applications.create!(state: 'corrections_required', review_cycle: 1)
    application.correction_items.create!(cycle: 0, code: 'OLD-1', narrative: 'Prior cycle item')
    application.correction_items.create!(cycle: 1, code: 'NEW-1', narrative: 'Current cycle item')

    expect(application.current_correction_items.map(&:code)).to eq(['NEW-1'])
  end

  it 'treats the most recent unsuperseded quote as the active one' do
    application = account.permit_applications.create!(state: 'fees_assessed')
    application.fee_quotes.create!(quote_reference: 'FQ-1', amount_cents: 1000,
                                   expires_at: 1.day.from_now, superseded_at: Time.zone.now)
    current = application.fee_quotes.create!(quote_reference: 'FQ-2', amount_cents: 1200,
                                             expires_at: 30.days.from_now)

    expect(application.active_fee_quote).to eq(current)
  end
end
