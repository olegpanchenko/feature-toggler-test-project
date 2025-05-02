module FeatureTogglers
  class ClientSettingsHandler
    def initialize(client_uuid:, global_settings:)
      @client_uuid = client_uuid
      @global_settings = global_settings
    end

    def upsert_client_setting_with_status(status_name, extra_data: {})
      status_value = ClientSettings::STATUS[status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      setting = ClientSettings.find_or_initialize_by(global_settings: @global_settings, client_uuid: @client_uuid)
      setting.status = status_value
      setting.extra_data = extra_data.presence

      if setting.save
        { success: true, setting: setting }
      else
        { success: false, errors: setting.errors.full_messages }
      end
    end

    def whitelisted_feature_names
      scope.where(status: ClientSettings::STATUS[:whitelisted])
    end

    def blacklisted_hard_feature_names
      scope.where(status: ClientSettings::STATUS[:blacklisted])
    end

    def disabled_by_client_hard_feature_names
      scope.where(status: ClientSettings::STATUS[:disabled_by_client])
    end

    private
    def scope
      @scope ||= ClientSettings.includes(:global_settings).where(global_settings: {status: GlobalSettings::STATUS[:enabled]})
    end
  end
end
