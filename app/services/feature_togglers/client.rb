# frozen_string_literal: true

module FeatureTogglers
  class Client
    class << self
      def global_settings_map
        RequestStore.store[:global_settings_map] ||= load_global_settings_map
      end

      def client_settings_map
        RequestStore.store[:client_settings_map] ||= load_client_settings_map
      end

      def clear_cache!
        RequestStore.store[:global_settings_map] = nil
        RequestStore.store[:client_settings_map] = nil
      end

      def refresh_cache!
        RequestStore.store[:global_settings_map] = load_global_settings_map
        RequestStore.store[:client_settings_map] = load_client_settings_map
      end

      private

      def load_global_settings_map
        FeatureTogglers::GlobalSettings
          .includes(:client_settings)
          .all
          .index_by(&:name)
      end

      def load_client_settings_map
        FeatureTogglers::ClientSettings
          .includes(:global_settings)
          .where(global_settings: global_settings_map.values)
          .group_by(&:client_uuid)
          .transform_values do |settings|
            settings.index_by { |s| s.global_settings.name }
          end
      end
    end

    attr_reader :client_uuid, :feature_name

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
      self.class.global_settings_map[feature_name]
    end

    def client_settings
      self.class.client_settings_map[client_uuid]&.[](feature_name)
    end
  end
end
