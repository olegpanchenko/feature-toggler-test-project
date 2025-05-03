require 'rails_helper'

RSpec.describe FeatureTogglers::Client, type: :model do
  let(:client_uuid) { '123' }
  let(:feature_name) { 'main_feature' }
  let(:client) { described_class.new(feature_name: feature_name, client_uuid: client_uuid) }
  let(:global_feature_settings) { create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled] }

  describe '#can_use?' do
    context 'when global settings exists' do
      before { global_feature_settings }

      context 'when global settings are enabled' do
        before do
          create :client_feature_settings,
              client_uuid: client_uuid,
              status: status,
              global_settings: global_feature_settings
        end

        context "when client_settings is whitelisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

          it 'returns true' do
            expect(client.can_use?).to be(true)
          end
        end

        context "when client_settings is blacklisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

          it 'returns false' do
            expect(client.can_use?).to be(false)
          end
        end
      end

      context 'when global settings are disabled' do
        before { global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:disabled]) }

        it 'returns false' do
          expect(client.can_use?).to be(false)
        end
      end
    end

    context 'when global settings do not exist' do
      let(:feature_name) { 'new_feature' }

      it 'returns false' do
        expect(client.can_use?).to be(false)
      end
    end
  end

  describe '#global_settings_handler' do
    it 'creates or updates global settings with a specific status' do
      result = client.enabled_global_settings!(extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
    end
  end

  describe '#client_settings_handler' do
    before { global_feature_settings }

    it 'creates or updates client settings with a specific status' do
      result = client.whitelisted_client_settings!(extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
    end
  end
end
