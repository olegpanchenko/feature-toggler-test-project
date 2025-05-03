module FeatureTogglers
  class ClientSettingsHandler
    def initialize(client_uuid:, global_settings:)
      @client_uuid = client_uuid
      @global_settings = global_settings
    end

    def whitelisted_feature_names
      feature_names_with(
        client_status: client_statuses[:whitelisted],
        allowed_global_statuses: global_statuses.values - [global_statuses[:disabled_hard]]
      )
    end

    def blacklisted_hard_feature_names
      feature_names_with(
        client_status: client_statuses[:blacklisted],
        allowed_global_statuses: [global_statuses[:enabled]]
      )
    end

    def disabled_by_client_hard_feature_names
      feature_names_with(
        client_status: client_statuses[:disabled_by_client],
        allowed_global_statuses: [global_statuses[:enabled]]
      )
    end

    def upsert_client_setting_with_status(status_name, extra_data: {})
      status_value = Configuration.statuses[:client][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      setting = ClientSettings.find_by(global_settings: @global_settings, client_uuid: @client_uuid)
      if setting.present?
        ClientSettings.update_resource(setting.id, status_value, extra_data)
      else
        ClientSettings.create_resource(@global_settings.id, @client_uuid, status_value, extra_data)
      end
    end

    private

    def feature_names_with(client_status:, allowed_global_statuses:)
      ClientSettings.includes(:global_settings)
        .where(global_settings: { status: allowed_global_statuses })
        .where(status: client_status)
        .pluck(:name)
    end

    def client_statuses
      Configuration.statuses[:client]
    end

    def global_statuses
      Configuration.statuses[:global]
    end

  end
end
