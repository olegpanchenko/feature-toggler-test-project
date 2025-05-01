FactoryBot.define do
  factory :global_feature_settings, class: 'FeatureTogglers::GlobalSettings' do
    
  end

  factory :feature_togglers_global_settings, class: 'FeatureTogglers::GlobalSettings' do
    name { 'test_feature' }
    status { FeatureTogglers::GlobalSettings::STATUS[:enabled] }
    extra_data { { 'key' => 'value' } }
  end
end
