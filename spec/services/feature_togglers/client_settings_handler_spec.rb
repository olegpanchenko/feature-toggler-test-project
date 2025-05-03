require 'rails_helper'

RSpec.describe FeatureTogglers::ClientSettingsHandler, type: :service do
  let(:client_uuid) { '123' }
  let(:feature_name) { 'main_feature' }
  let(:global_settings) { setting = create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled] }
  let(:extra_data) { { "some_key" => 'some_value' } }

  describe '#upsert_client_setting_with_status' do
    subject { described_class.new(client_uuid: client_uuid, global_settings: global_settings) }

    context 'when status is valid' do
      it 'creates a new client setting with the correct status' do
        result = subject.upsert_client_setting_with_status('whitelisted', extra_data: extra_data)

        expect(result[:success]).to be(true)
        expect(result[:setting]).to be_persisted
        expect(result[:setting].status).to eq(FeatureTogglers::ClientSettings::STATUS[:whitelisted])
        expect(result[:setting].extra_data).to eq(extra_data)
      end

      it 'updates an existing client setting with the correct status' do
        setting = create :client_feature_settings,
              client_uuid: client_uuid,
              status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
              global_settings: global_settings
        result = subject.upsert_client_setting_with_status('whitelisted', extra_data: extra_data)

        expect(result[:success]).to be(true)
        expect(result[:setting].status).to eq(FeatureTogglers::ClientSettings::STATUS[:whitelisted])
      end
    end

    context 'when status is invalid' do
      it 'returns an error' do
        result = subject.upsert_client_setting_with_status('invalid_status')

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq('Invalid status: invalid_status')
      end
    end
  end

  describe '#whitelisted_feature_names' do
    it 'returns only whitelisted client settings with enabled global settings' do
      enabled_global = global_settings
      disabled_global = create(:feature_togglers_global_settings, name: 'disabled feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled])
      disabled_hard_global = create(:feature_togglers_global_settings, name: 'disabled hard feature', status: FeatureTogglers::GlobalSettings::STATUS[:disabled_hard])

      create(:feature_togglers_client_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:whitelisted], global_settings: enabled_global)
      create(:feature_togglers_client_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:whitelisted], global_settings: disabled_global)
      create(:feature_togglers_client_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:whitelisted], global_settings: disabled_hard_global)

      handler = described_class.new(client_uuid: client_uuid, global_settings: enabled_global)

      expect(handler.whitelisted_feature_names.count).to eq(2)
    end
  end

  describe '#blacklisted_hard_feature_names' do
    it 'returns only blacklisted settings with enabled global settings' do
      create(:feature_togglers_client_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:blacklisted], global_settings: global_settings)

      handler = described_class.new(client_uuid: client_uuid, global_settings: global_settings)

      expect(handler.blacklisted_hard_feature_names.count).to eq(1)
    end
  end

  describe '#disabled_by_client_hard_feature_names' do
    it 'returns only disabled_by_client settings with enabled global settings' do
      create(:feature_togglers_client_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:disabled_by_client], global_settings: global_settings)

      handler = described_class.new(client_uuid: client_uuid, global_settings: global_settings)

      expect(handler.disabled_by_client_hard_feature_names.count).to eq(1)
    end
  end
end
