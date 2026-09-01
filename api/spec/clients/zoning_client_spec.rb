require 'rails_helper'

RSpec.describe Clients::ZoningClient do
  let(:transport) { instance_double(Clients::HttpClient) }

  before do
    allow(Clients::HttpClient).to receive(:new).and_return(transport)
  end

  it 'submits a check and gets a handle back' do
    allow(transport).to receive(:post).and_return({ 'handle' => 'zc-1001', 'status' => 'pending' })

    response = transport.post('/checks', { reference: 'PA-2026-AAAAAA' })

    expect(response['handle']).to eq('zc-1001')
    expect(response['status']).to eq('pending')
  end

  it 'reads a completed result by handle' do
    allow(transport).to receive(:get).and_return({ 'status' => 'complete', 'outcome' => 'permissible' })

    result = transport.get('/checks/zc-1001')

    expect(result['outcome']).to eq('permissible')
  end

  it 'surfaces an indeterminate outcome' do
    allow(transport).to receive(:get).and_return({ 'status' => 'complete', 'outcome' => 'indeterminate' })

    expect(transport.get('/checks/zc-1001')['outcome']).to eq('indeterminate')
  end

  it 'treats a 503 from the index rebuild as retryable' do
    error = Clients::ServiceError.new('zoning returned 503', status: 503)
    expect(error.retryable?).to be(true)
  end
end
