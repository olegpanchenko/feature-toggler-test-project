# frozen_string_literal: true

module FeatureTogglers
  class Client
    attr_reader :client_uuid, :feature_name

    Configuration.statuses[:global].each do |status_name, status_value|
      define_method("#{status_name}_global_settings!") do |extra_data: {}|
        global_settings_handler.upsert_global_setting_with_status(status_name, extra_data: extra_data)
      end
    end

    Configuration.statuses[:client].each do |status_name, status_value|
      define_method("#{status_name}_client_settings!") do |extra_data: {}|
        client_settings_handler.upsert_client_setting_with_status(status_name, extra_data: extra_data)
      end
    end

    def initialize(feature_name:, client_uuid:)
      @feature_name = feature_name
      @client_uuid = client_uuid
    end

    def can_use?
      return false unless global_enabled?
      return false if client_disabled?
      return false if globally_soft_disabled_but_client_not_whitelisted?

      true
    end

    def refresh_settings
      @global_settings = ClientFeatureLoader.refresh(@global_settings) if @global_settings
    end

    def all_global_feature_names
      global_settings_handler.all_feature_names
    end

    def enabled_global_feature_names
      global_settings_handler.enabled_feature_names
    end

    def disabled_global_hard_feature_names
      global_settings_handler.disabled_hard_feature_names
    end

    def whitelisted_feature_names
      client_settings_handler.whitelisted_feature_names
    end

    def blacklisted_hard_feature_names
      client_settings_handler.blacklisted_hard_feature_names
    end

    def disabled_by_client_hard_feature_names
      client_settings_handler.disabled_by_client_hard_feature_names
    end

    private

    def global_enabled?
      global_settings.present? && !global_settings.disabled_hard?
    end

    def client_disabled?
      client_settings&.blacklisted? || client_settings&.disabled_by_client?
    end

    def globally_soft_disabled_but_client_not_whitelisted?
      global_settings.disabled? && (client_settings.blank? || !client_settings.whitelisted?)
    end

    def global_settings
      @global_settings ||= ClientFeatureLoader.load(feature_name: feature_name, client_uuid: client_uuid)
    end

    def client_settings
      @client_settings ||= global_settings.client_settings.find { |cs| cs.client_uuid == client_uuid }
    end

    def global_settings_handler
      @global_settings_handler ||= GlobalSettingsHandler.new(feature_name: feature_name)
    end

    def client_settings_handler
      @client_settings_handler ||= ClientSettingsHandler.new(client_uuid: client_uuid, global_settings: global_settings)
    end
  end
end
