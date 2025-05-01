module FeatureTogglers
  class GlobalSettings < ApplicationRecord
    self.table_name = 'feature_toggle_global_settings'
    store_accessor :extra_data
 
    STATUS = {
      # sync with the one from AMS if changing anything
      disabled: 1,
      disabled_hard: 2,
      enabled: 3
    }.freeze
 
    has_many :client_settings, class_name: 'FeatureTogglers::ClientSettings',
                               foreign_key: 'feature_toggle_settings_id',
                               dependent: :destroy, inverse_of: :global_settings
 
    validates :status, inclusion: { in: STATUS.values }
 
    validates :name, presence: true, uniqueness: true
 
    def self.update_resource(id, status, extra_data)
      settings = self.find(id)
      save_resource(settings, status, extra_data)
    end
 
    def disabled_hard?
      status == STATUS[:disabled_hard]
    end
 
    def disabled?
      status == STATUS[:disabled]
    end
 
    def enabled?
      status == STATUS[:enabled]
    end
 
    def self.create_resource(name, status, extra_data)
      settings = self.new(name: name)
      save_resource(settings, status, extra_data)
    end
 
    def self.save_resource(settings, status, extra_data)
      settings.status = status
      settings.extra_data = extra_data.present? ? extra_data.filter { |_, v| v.present? } : extra_data
 
      return { success: true } if settings.save
 
      { success: false, errors: settings.errors.full_messages }
    end
  end
end
 