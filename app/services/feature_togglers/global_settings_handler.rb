module FeatureTogglers
  class GlobalSettingsHandler
    def initialize(feature_name:)
      @feature_name = feature_name
    end

    def all_feature_names
      GlobalSettings.pluck(:name)
    end

    def enabled_feature_names
      GlobalSettings.where(status: Configuration.statuses[:global][:enabled]).pluck(:name)
    end

    def disabled_feature_names
      GlobalSettings.where(status: Configuration.statuses[:global][:disabled]).pluck(:name)
    end

    def disabled_hard_feature_names
      GlobalSettings.where(status: Configuration.statuses[:global][:disabled_hard]).pluck(:name)
    end

    def upsert_global_setting_with_status(status_name, extra_data: {})
      status_value = Configuration.statuses[:global][status_name.to_sym]
      return { success: false, error: "Invalid status: #{status_name}" } unless status_value

      setting = GlobalSettings.find_by(name: @feature_name)
      if setting.present?
        GlobalSettings.update_resource(setting.id, status_value, extra_data)
      else
        GlobalSettings.create_resource(@feature_name, status_value, extra_data)
      end
    end
  end
end
