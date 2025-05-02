require 'rails_helper'

RSpec.describe FeatureTogglers::Client, type: :model do
  let(:client_uuid) { 'test-uuid' }
  let(:feature_name) { 'Awesome Feature' }
  let!(:global_feature_settings) { create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled] }

  subject { described_class.new(feature_name: global_feature_settings.name, client_uuid: client_uuid) }

  after { RequestStore.clear! }

  describe '#can_use?' do
    context "when global feature is hard disabled" do
      before { global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:disabled_hard]) }

      it "returns false" do
        expect(subject.can_use?).to eq(false)
      end
    end

    context "when client is blacklisted" do
      before do
        global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:enabled])
        create :client_feature_settings,
            client_uuid: client_uuid,
            status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
            global_settings: global_feature_settings
      end

      it "returns false" do
        expect(subject.can_use?).to eq(false)
      end
    end

    context "when global is soft-disabled and client is not whitelisted" do
      before do
        global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:disabled])
        create :client_feature_settings,
            client_uuid: client_uuid,
            status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
            global_settings: global_feature_settings
      end

      it "returns true" do
        expect(subject.can_use?).to eq(true)
      end
    end

    context "when feature is globally enabled and client is eligible" do
      before do
        global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:enabled])
        create :client_feature_settings,
            client_uuid: client_uuid, 
            status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
            global_settings: global_feature_settings
      end

      it "returns true" do
        expect(subject.can_use?).to eq(true)
      end
    end

    context "with caching" do
      it "caches global settings per request" do
        expect(RequestStore.store[:global_settings_map]).to be_nil
        subject.can_use?
        expect(RequestStore.store[:global_settings_map]).not_to be_nil
      end
    end
  end

  describe 'refreshing feature settings mid-request' do
    before { global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:disabled_hard]) }

    it 'reflects new settings after cache refresh' do
      client = FeatureTogglers::Client.new(client_uuid: client_uuid, feature_name: feature_name)

      expect(client.can_use?).to eq(false)

      global_feature_settings.update!(status: FeatureTogglers::GlobalSettings::STATUS[:enabled])

      FeatureTogglers::Client.refresh_cache!

      expect(client.can_use?).to eq(true)
    end
  end
end
