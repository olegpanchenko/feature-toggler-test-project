FactoryBot.define do
  factory :client_feature_settings, class: 'FeatureTogglers::ClientSettings' do
    
  end

  factory :feature_togglers_client_settings, class: 'FeatureTogglers::ClientSettings' do
    client_uuid { '123e4567-e89b-12d3-a456-426614174000' }
    feature_toggle_settings_id { 1 }
    status { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }
    extra_data { { 'key' => 'value' } }
  end
end
