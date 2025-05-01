class ClientFeatureSettings
  attr_reader :client_uuid, :feature_name

  def initialize(feature_name:, client_uuid:)
    @feature_name = feature_name
    @client_uuid = client_uuid
  end

  def can_use?
    return false if global_settings.blank? || global_settings.disabled_hard?

    return false if client_settings&.blacklisted? || client_settings&.disabled_by_client?
    return false if global_settings.disabled? && (client_settings.blank? || !client_settings.whitelisted?)

    true
  end

  def thresholds(keys)
    return keys.to_h { |key| [key, nil] } if global_settings.blank?

    global_extra_data = global_settings.extra_data || {}
    result = keys.to_h { |key| [key, nil] }
    client_extra_data = client_settings&.extra_data || {}

    keys.each do |key|
      if client_extra_data.key?(key)
        result[key] = client_extra_data[key]
      elsif global_extra_data.key?(key)
        result[key] = global_extra_data[key]
      end
    end

    result
  end

  class << self
    def ai_translate?(uuid)
      feature_name = 'ai_translation'
      return true if new(feature_name: feature_name, client_uuid: uuid).can_use?

      feature_enabled_for_organization?(feature_name, uuid)
    end

    def save_segment_post_processors?
      feature_name = 'save_segment_post_processors'
      new(feature_name: feature_name, client_uuid: nil).can_use?
    end

    def second_ai_translate?(uuid)
      feature_name = 'second_ai_translation'
      return true if new(feature_name: feature_name, client_uuid: uuid).can_use?

      feature_enabled_for_organization?(feature_name, uuid)
    end

    def generate_website_context?(uuid)
      new(feature_name: 'website_context', client_uuid: uuid).can_use?
    end

    def website_context_timeout?(uuid)
      new(feature_name: 'timeout_website_context', client_uuid: uuid).can_use?
    end

    def marker_notify?(uuid)
      new(feature_name: 'marker_notify', client_uuid: uuid).can_use?
    end

    def tokenize_emoji?
      feature_name = 'tokenize_emoji'
      new(feature_name: feature_name, client_uuid: nil).can_use?
    end

    def analyze_text?(uuid)
      feature_name = 'analyze_text'
      new(feature_name: feature_name, client_uuid: uuid).can_use?
    end

    private

    def feature_enabled_for_organization?(feature_name, uuid)
      global_settings = FeatureTogglers::GlobalSettings.find_by(name: feature_name)
      return false if global_settings.blank?

      return false if global_settings.extra_data.blank? || global_settings.extra_data['enabled_for_organizations_newer_than_integer_date'].blank?

      organization = Ams::Organization.find_by(uuid: uuid)
      return false if organization.blank?

      organization.created_at.to_i > global_settings.extra_data['enabled_for_organizations_newer_than_integer_date'].to_i
    end
  end

  private

  def global_settings
    @global_settings ||= FeatureTogglers::GlobalSettings.find_by(name: feature_name)
  end

  def client_settings
    @client_settings ||= FeatureTogglers::ClientSettings.find_by(
      client_uuid: client_uuid,
      global_settings: global_settings
    )
  end
end
