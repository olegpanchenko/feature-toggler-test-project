# frozen_string_literal: true

module FeatureTogglers
  class Client
    attr_reader :client_uuid

    def initialize(client_uuid:, cache: FeatureTogglers::Cache.new)
      @client_uuid = client_uuid
      @cache = cache
    end

    def enabled?(feature_name)
      global_settings = fetch_global_settings(feature_name)
      return false if global_settings.nil? || global_settings.disabled_hard?

      client_settings = fetch_client_settings(feature_name, global_settings)
      return client_settings&.whitelisted? || (global_settings.enabled? && client_settings.nil?)
    end

    def refresh_settings
      @cache.clear
    end

    Configuration.statuses[:global].each do |status_name, status_value|
      define_method("#{status_name}_global_settings!") do |feature_name, extra_data: {}|
        upsert_global_settings(feature_name, status_name, extra_data).tap do
          refresh_settings
        end
      end
    end

    Configuration.statuses[:client].each do |status_name, status_value|
      define_method("#{status_name}_client_settings!") do |feature_name, extra_data: {}|
        upsert_client_settings(feature_name, client_uuid, status_name, extra_data).tap do
          refresh_settings
        end
      end
    end

    private

    def fetch_global_settings(feature_name)
      if @cache.global_features.nil?
        all_settings = GlobalSettings.all.to_a
        @cache.set_global_features(all_settings)
      end

      @cache.global_features.find { |gs| gs.name == feature_name }
    end

    def fetch_client_settings(feature_name, global_settings)
      @cache.client_settings(feature_name) ||
        find_client_settings(client_uuid, global_settings).tap do |settings|
          @cache.set_client_settings(feature_name, settings)
        end
    end

    def find_global_settings(feature_name)
      GlobalSettings.find_by(name: feature_name)
    end

    def find_client_settings(client_uuid, global_settings)
      ClientSettings.find_by(
        client_uuid: client_uuid,
        global_settings: global_settings
      )
    end

    def upsert_global_settings(feature_name, status_name, extra_data)
      status_value = Configuration.statuses[:global][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_settings(feature_name)
      if global_settings.present?
        GlobalSettings.update_resource(global_settings.id, status_value, extra_data)
      else
        GlobalSettings.create_resource(feature_name, status_value, extra_data)
      end
    end

    def upsert_client_settings(feature_name, client_uuid, status_name, extra_data)
      status_value = Configuration.statuses[:client][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_settings(feature_name)
      return { success: false, error: "Invalid feature name: #{feature_name}" } unless global_settings

      setting = fetch_client_settings(feature_name, global_settings)
      if setting.present?
        ClientSettings.update_resource(setting.id, status_value, extra_data)
      else
        ClientSettings.create_resource(global_settings.id, client_uuid, status_value, extra_data)
      end
    end
  end
end
