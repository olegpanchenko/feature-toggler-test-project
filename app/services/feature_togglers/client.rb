# frozen_string_literal: true

module FeatureTogglers
  class Client
    attr_reader :client_uuid

    def initialize(client_uuid:, cache: FeatureTogglers::Cache.new)
      @client_uuid = client_uuid
      @cache = cache
    end

    def enabled?(feature_name)
      global_settings = fetch_global_setting(feature_name)
      return false if global_settings.nil? || global_settings.disabled_hard?

      client_settings = fetch_client_setting(feature_name, global_settings)
      if client_settings.nil? && global_settings.enabled? && global_settings.extra_data&.key?('rollout_percentage')
        client_settings = create_percentage_based_settings(feature_name, global_settings)
      end

      return client_settings&.whitelisted? || (global_settings.enabled? && client_settings.nil?)
    end

    def refresh_settings!
      @cache.clear!
    end

    Configuration::STATUSES[:global].each do |status_name, status_value|
      verb = Configuration::VERBS[:global][status_name]

      define_method("#{verb}_global_setting!") do |feature_name, extra_data: {}|
        upsert_global_setting(feature_name, status_name, extra_data).tap do
          refresh_settings!
        end
      end
    end

    Configuration::STATUSES[:client].each do |status_name, status_value|
      verb = Configuration::VERBS[:client][status_name]

      define_method("#{verb}_client_setting!") do |feature_name, extra_data: {}|
        upsert_client_setting(feature_name, client_uuid, status_name, extra_data).tap do
          refresh_settings!
        end
      end
    end

    private

    def create_percentage_based_settings(feature_name, global_settings)
      percentage = global_settings.extra_data['rollout_percentage'].to_i
      return nil if percentage <= 0 || percentage > 100

      seed = "#{client_uuid}-#{feature_name}".hash
      random = Random.new(seed)
      is_whitelisted = random.rand(100) < percentage

      status = is_whitelisted ?
        Configuration::STATUSES[:client][:whitelisted] :
        Configuration::STATUSES[:client][:blacklisted]

      client_settings = ClientSettings.create!(
        global_settings: global_settings,
        client_uuid: client_uuid,
        status: status,
        extra_data: {
          'generated_by_rollout' => true,
          'assigned_by_percentage' => percentage
        }
      )

      fetch_client_setting(feature_name, global_settings)
    end

    def fetch_global_setting(feature_name)
      if @cache.global_features.nil?
        all_settings = GlobalSettings.all.to_a
        @cache.set_global_features(all_settings)
      end

      @cache.global_features.find { |gs| gs.name == feature_name }
    end

    def fetch_client_setting(feature_name, global_settings)
      if @cache.client_settings.nil?
        all_settings = ClientSettings.where(client_uuid: client_uuid).to_a
        @cache.set_client_settings(all_settings)
      end

      @cache.client_settings.find { |cs| cs.feature_toggle_settings_id == global_settings.id }
    end

    def upsert_global_setting(feature_name, status_name, extra_data)
      status_value = Configuration::STATUSES[:global][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_setting(feature_name)
      if global_settings.present?
        GlobalSettings.update_resource(global_settings.id, status_value, extra_data)
      else
        GlobalSettings.create_resource(feature_name, status_value, extra_data)
      end
    end

    def upsert_client_setting(feature_name, client_uuid, status_name, extra_data)
      status_value = Configuration::STATUSES[:client][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_setting(feature_name)
      return { success: false, error: "Invalid feature name: #{feature_name}" } unless global_settings

      setting = fetch_client_setting(feature_name, global_settings)
      if setting.present?
        ClientSettings.update_resource(setting.id, status_value, extra_data)
      else
        ClientSettings.create_resource(global_settings.id, client_uuid, status_value, extra_data)
      end
    end
  end
end
