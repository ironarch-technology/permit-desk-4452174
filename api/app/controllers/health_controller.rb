class HealthController < ApplicationController
  def show
    checks = {
      database: database_ok?,
      bus: bus_ok?
    }

    status = checks.values.all? ? :ok : :service_unavailable
    render json: { status: status == :ok ? 'ok' : 'degraded', checks: checks }, status: status
  end

  private

  def database_ok?
    ActiveRecord::Base.connection.execute('SELECT 1').present?
  rescue StandardError
    false
  end

  def bus_ok?
    Bus::Producer.client.partition_count(Bus::Topics::REVIEW_SUBMISSIONS).to_i.positive?
  rescue StandardError
    false
  end
end
