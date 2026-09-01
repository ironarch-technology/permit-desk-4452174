require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'

Bundler.require(*Rails.groups)

module PermitDesk
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.eager_load = false
    config.time_zone = 'America/New_York'
    config.active_record.default_timezone = :utc

    config.x.services = config_for(:services)
  end
end
