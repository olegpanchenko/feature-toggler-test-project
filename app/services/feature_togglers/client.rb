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

      if rollout_enabled?(global_settings)
        client_settings = handle_percentage_rollout(global_settings, client_settings)
      end

      client_settings&.whitelisted? || (global_settings.enabled? && client_settings.nil?)
    end

    def refresh_settings!
      @cache.clear!
    end

    FeatureTogglers::Configuration::STATUSES[:global].each do |status_name, status_value|
      verb = FeatureTogglers::Configuration::VERBS[:global][status_name]

      define_method("#{verb}_global_setting!") do |feature_name, extra_data: {}|
        upsert_global_setting(feature_name, status_name, extra_data).tap do
          refresh_settings!
        end
      end
    end

    FeatureTogglers::Configuration::STATUSES[:client].each do |status_name, status_value|
      verb = FeatureTogglers::Configuration::VERBS[:client][status_name]

      define_method("#{verb}_client_setting!") do |feature_name, extra_data: {}|
        upsert_client_setting(feature_name, client_uuid, status_name, extra_data).tap do
          refresh_settings!
        end
      end
    end

    private

    def rollout_enabled?(global_settings)
      global_settings.enabled? && global_settings.extra_data&.key?('rollout_percentage')
    end

    def handle_percentage_rollout(global_settings, client_settings)
      current_percentage = global_settings.extra_data['rollout_percentage'].to_i
      should_be_whitelisted = rollout_whitelisted?(global_settings)

      if client_settings.nil?
        return create_percentage_based_settings(global_settings, should_be_whitelisted)
      end

      if client_settings.extra_data&.key?('generated_by_rollout')
        return update_percentage_based_settings(client_settings, global_settings, should_be_whitelisted)
      end

      client_settings
    end

    def rollout_whitelisted?(global_settings)
      percentage = global_settings.extra_data['rollout_percentage'].to_i
      return false if percentage <= 0 || percentage > 100

      seed = "#{client_uuid}-#{global_settings.name}".hash
      Random.new(seed).rand(100) < percentage
    end

    def create_percentage_based_settings(global_settings, is_whitelisted)
      status = is_whitelisted ?
        FeatureTogglers::Configuration::STATUSES[:client][:whitelisted] :
        FeatureTogglers::Configuration::STATUSES[:client][:blacklisted]

      FeatureTogglers::ClientSettings.create_resource(global_settings.id, client_uuid, status, {
        'generated_by_rollout' => true,
        'assigned_by_percentage' => global_settings.extra_data['rollout_percentage'].to_i
      })

      fetch_client_setting(global_settings.name, global_settings)
    end

    def update_percentage_based_settings(client_settings, global_settings, is_whitelisted)
      current_percentage = global_settings.extra_data['rollout_percentage'].to_i
      assigned = client_settings.extra_data['assigned_by_percentage'].to_i

      return client_settings if assigned == current_percentage

      previously_whitelisted = client_settings.whitelisted?

      if assigned > current_percentage && previously_whitelisted
        status = is_whitelisted ?
          FeatureTogglers::Configuration::STATUSES[:client][:whitelisted] :
          FeatureTogglers::Configuration::STATUSES[:client][:blacklisted]
      end

      if assigned < current_percentage && !previously_whitelisted
        status = is_whitelisted ?
          FeatureTogglers::Configuration::STATUSES[:client][:whitelisted] :
          FeatureTogglers::Configuration::STATUSES[:client][:blacklisted]
      end

      FeatureTogglers::ClientSettings.update_resource(client_settings.id, status, {
        'generated_by_rollout' => true,
        'assigned_by_percentage' => global_settings.extra_data['rollout_percentage'].to_i
      })

      fetch_client_setting(global_settings.name, global_settings)
    end

    def fetch_global_setting(feature_name)
      if @cache.global_features.nil?
        all_settings = FeatureTogglers::GlobalSettings.all.to_a
        @cache.set_global_features(all_settings)
      end

      @cache.global_features.find { |gs| gs.name == feature_name }
    end

    def fetch_client_setting(feature_name, global_settings)
      if @cache.client_settings.nil?
        all_settings = FeatureTogglers::ClientSettings.where(client_uuid: client_uuid).to_a
        @cache.set_client_settings(all_settings)
      end

      @cache.client_settings.find { |cs| cs.feature_toggle_settings_id == global_settings.id }
    end

    def upsert_global_setting(feature_name, status_name, extra_data)
      status_value = FeatureTogglers::Configuration::STATUSES[:global][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_setting(feature_name)
      if global_settings.present?
        FeatureTogglers::GlobalSettings.update_resource(global_settings.id, status_value, extra_data)
      else
        FeatureTogglers::GlobalSettings.create_resource(feature_name, status_value, extra_data)
      end
    end

    def upsert_client_setting(feature_name, client_uuid, status_name, extra_data)
      status_value = FeatureTogglers::Configuration::STATUSES[:client][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      global_settings = fetch_global_setting(feature_name)
      return { success: false, error: "Invalid feature name: #{feature_name}" } unless global_settings

      setting = fetch_client_setting(feature_name, global_settings)
      if setting.present?
        FeatureTogglers::ClientSettings.update_resource(setting.id, status_value, extra_data)
      else
        FeatureTogglers::ClientSettings.create_resource(global_settings.id, client_uuid, status_value, extra_data)
      end
    end
  end
end
