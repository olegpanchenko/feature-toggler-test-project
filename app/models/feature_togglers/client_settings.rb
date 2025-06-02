module FeatureTogglers
  class ClientSettings < ApplicationRecord
    self.table_name = 'feature_toggle_client_settings'
  
    belongs_to :global_settings, class_name: 'FeatureTogglers::GlobalSettings',
                                  foreign_key: 'feature_toggle_settings_id', inverse_of: :client_settings
  
    validates :status, presence: true
    validates :client_uuid, presence: true
    validates :feature_toggle_settings_id, presence: true
    validates :client_uuid, uniqueness: { scope: :feature_toggle_settings_id, case_sensitive: false }
  
    STATUS = {
      # sync with the one from AMS if changing anything
      whitelisted: 1,
      blacklisted: 2,
      disabled_by_client: 3
    }.freeze
  
    validates :status, inclusion: { in: STATUS.values }
  
    def whitelisted?
      status == STATUS[:whitelisted]
    end
  
    def blacklisted?
      status == STATUS[:blacklisted]
    end
  
    def disabled_by_client?
      status == STATUS[:disabled_by_client]
    end

    def generated_by_rollout?
      extra_data&.fetch('generated_by_rollout', false)
    end

    def assigned_by_percentage
      extra_data&.fetch('assigned_by_percentage', nil)&.to_i
    end
  
    def self.update_resource(id, status, extra_data)
      client_settings = self.find(id)
      save_resource(client_settings, status, extra_data)
    end
  
    def self.create_resource(global_settings_id, client_uuid, status, extra_data)
      fts = FeatureTogglers::GlobalSettings.find_by(id: global_settings_id)
      client_settings = self.new(client_uuid: client_uuid, global_settings: fts)
      save_resource(client_settings, status, extra_data)
    end
  
    def self.save_resource(client_settings, status, extra_data)
      client_settings.status = status
      client_settings.extra_data = extra_data.present? ? extra_data.filter { |_, v| v.present? } : extra_data
  
      return { success: true } if client_settings.save
  
      { success: false, errors: client_settings.errors.full_messages }
    end
  end
end
