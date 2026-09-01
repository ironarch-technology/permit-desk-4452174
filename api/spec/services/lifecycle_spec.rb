require 'rails_helper'

RSpec.describe Lifecycle do
  let(:account) do
    Account.create!(email: 'spec-applicant@example.com', full_name: 'Spec Applicant',
                    password: 'spec-password')
  end

  let(:parcel) do
    Parcel.create!(apn: '000-000-001', street_address: '1 Spec Way', postal_code: '19714',
                   district: 'central', zone_code: 'R-1')
  end

  let(:application) do
    account.permit_applications.create!(state: 'draft', parcel: parcel, work_type: 'reroof',
                                       scope_of_work: 'Replace shingles',
                                       declared_valuation_cents: 15_000_00,
                                       applicant_name: 'Spec Applicant',
                                       applicant_email: 'spec-applicant@example.com')
  end

  describe '.permitted?' do
    it 'allows a draft to be submitted' do
      expect(described_class.permitted?('draft', 'submitted')).to be(true)
    end

    it 'refuses to move backwards out of plan review' do
      expect(described_class.permitted?('plan_review', 'submitted')).to be(false)
    end

    it 'refuses any transition out of a terminal state' do
      %w[denied withdrawn expired].each do |terminal|
        expect(described_class::ALLOWED.fetch(terminal)).to be_empty
      end
    end

    it 'allows corrections to return to plan review' do
      expect(described_class.permitted?('corrections_required', 'plan_review')).to be(true)
    end
  end

  describe '.apply!' do
    it 'writes the new state' do
      described_class.apply!(application, to: 'submitted', actor: 'spec')
      expect(application.reload.state).to eq('submitted')
    end

    it 'records a transition carrying the actor and the source system' do
      described_class.apply!(application, to: 'submitted', actor: 'account:7', reason: 'sent')

      transition = application.transitions.last
      expect(transition.from_state).to eq('draft')
      expect(transition.to_state).to eq('submitted')
      expect(transition.actor).to eq('account:7')
      expect(transition.source_system).to eq('permit-desk')
      expect(transition.reason).to eq('sent')
    end

    it 'runs the block it is given' do
      called = false
      described_class.apply!(application, to: 'submitted', actor: 'spec') { called = true }
      expect(called).to be(true)
    end
  end
end
