require 'rails_helper'

RSpec.describe ClientFeatureSettings, type: :model do
  let(:client_uuid) { 'test-uuid' }

  describe '#can_use?' do
    let(:feature_name) { 'Test Feature' }
    subject { ClientFeatureSettings.new(feature_name: feature_name, client_uuid: client_uuid) }

    context 'when feature settings do not exist' do
      it 'returns false' do
        expect(subject.can_use?).to be(false)
      end
    end

    context 'when feature is disabled hard' do
      let!(:global_feature_settings) do
        create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:disabled_hard]
      end
      let!(:client_feature_settings) do
        create :client_feature_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
                                          global_settings: global_feature_settings
      end

      it 'returns false' do
        expect(subject.can_use?).to be(false)
      end
    end

    context 'when client is blacklisted' do
      let!(:global_feature_settings) do
        create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled]
      end
      let!(:client_feature_settings) do
        create :client_feature_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
                                          global_settings: global_feature_settings
      end

      it 'returns false' do
        expect(subject.can_use?).to be(false)
      end
    end

    context 'when feature is disabled and client is not whitelisted' do
      let!(:global_feature_settings) do
        create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:disabled]
      end

      it 'returns false' do
        expect(subject.can_use?).to be(false)
      end
    end

    context 'when client is allowed to use the feature' do
      let!(:global_feature_settings) do
        create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:disabled]
      end
      let!(:client_feature_settings) do
        create :client_feature_settings, client_uuid: client_uuid, status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
                                          global_settings: global_feature_settings
      end

      it 'returns true' do
        expect(subject.can_use?).to be(true)

        global_feature_settings.update(status: FeatureTogglers::GlobalSettings::STATUS[:enabled])
        client_feature_settings.destroy
        expect(subject.can_use?).to be(true)
      end
    end
  end
end
