module FeatureTogglers
  class ClientFeatureLoader
    def self.load(feature_name:, client_uuid:)
      global_settings_table = GlobalSettings.arel_table
      client_settings_table = ClientSettings.arel_table

      GlobalSettings
        .includes(:client_settings)
        .left_joins(:client_settings)
        .where(global_settings_table[:name].eq(feature_name))
        .where(
          client_settings_table[:client_uuid].eq(client_uuid)
            .or(client_settings_table[:client_uuid].eq(nil))
        )
        .distinct
        .load
        .first
    end

    def self.refresh(global_settings)
      global_settings.reload
    end
  end
end
