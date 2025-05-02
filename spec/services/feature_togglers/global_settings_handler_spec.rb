require 'rails_helper'

RSpec.describe FeatureTogglers::GlobalSettingsHandler, type: :service do
  let(:feature_name) { 'main_feature' }
  let(:extra_data) { { "some_key" => 'some_value' } }

  describe '#all_feature_names' do
    it 'returns all feature names' do
      create(:feature_togglers_global_settings, name: 'main_feature', status: FeatureTogglers::GlobalSettings::STATUS[:enabled])
      create(:feature_togglers_global_settings, name: 'another_feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled])

      handler = described_class.new(feature_name: feature_name)

      expect(handler.all_feature_names).to include('main_feature', 'another_feature')
    end
  end

  describe '#enabled_feature_names' do
    it 'returns only enabled feature names' do
      create(:feature_togglers_global_settings, name: 'main_feature', status: FeatureTogglers::GlobalSettings::STATUS[:enabled])
      create(:feature_togglers_global_settings, name: 'another_feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled])

      handler = described_class.new(feature_name: feature_name)

      expect(handler.enabled_feature_names).to include('main_feature')
      expect(handler.enabled_feature_names).not_to include('another_feature')
    end
  end

  describe '#disabled_feature_names' do
    it 'returns only disabled feature names' do
      create(:feature_togglers_global_settings, name: 'main_feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled])
      create(:feature_togglers_global_settings, name: 'another_feature', status: FeatureTogglers::GlobalSettings::STATUS[:enabled])

      handler = described_class.new(feature_name: feature_name)

      expect(handler.disabled_feature_names).to include('main_feature')
      expect(handler.disabled_feature_names).not_to include('another_feature')
    end
  end

  describe '#disabled_hard_feature_names' do
    it 'returns only disabled_hard feature names' do
      create(:feature_togglers_global_settings, name: 'main_feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled_hard])
      create(:feature_togglers_global_settings, name: 'another_feature', status: FeatureTogglers::GlobalSettings::STATUS[:enabled])

      handler = described_class.new(feature_name: feature_name)

      expect(handler.disabled_hard_feature_names).to include('main_feature')
      expect(handler.disabled_hard_feature_names).not_to include('another_feature')
    end
  end

  describe '#upsert_global_setting_with_status' do
    subject { described_class.new(feature_name: feature_name) }

    context 'when status is valid' do
      it 'creates a new global setting with the correct status' do
        result = subject.upsert_global_setting_with_status('enabled', extra_data: extra_data)

        expect(result[:success]).to be(true)
        expect(result[:setting]).to be_persisted
        expect(result[:setting].status).to eq(FeatureTogglers::GlobalSettings::STATUS[:enabled])
        expect(result[:setting].extra_data).to eq(extra_data)
      end

      it 'updates an existing global setting with the correct status' do
        setting = create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:disabled]
        result = subject.upsert_global_setting_with_status('enabled', extra_data: extra_data)

        expect(result[:success]).to be(true)
        expect(result[:setting].status).to eq(FeatureTogglers::GlobalSettings::STATUS[:enabled])
      end
    end

    context 'when status is invalid' do
      it 'returns an error' do
        result = subject.upsert_global_setting_with_status('invalid_status')

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid status: invalid_status')
      end
    end
  end
end
