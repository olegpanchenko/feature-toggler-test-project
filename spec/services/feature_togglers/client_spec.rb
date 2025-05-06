require 'rails_helper'

RSpec.describe FeatureTogglers::Client, type: :model do
  let(:client_uuid) { '123' }
  let(:feature_name) { 'main_feature' }
  let(:client) { described_class.new(client_uuid: client_uuid) }
  let(:global_feature_settings) { create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled] }

  describe '#enabled?' do
    subject { client.enabled?(feature_name) }

    context 'when global settings do not exist' do
      let(:feature_name) { 'new_feature' }

      it { is_expected.to be_falsey }
    end

    context 'when global settings exists' do
      before do
        global_feature_settings
        global_feature_settings.update!(status: global_status)
      end

      context 'when global settings are disabled_hard' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:disabled_hard] }

        it { is_expected.to be_falsey }
      end

      context 'when global settings are disabled' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:disabled] }
        let!(:client_feature_settings) {
          create :client_feature_settings,
            client_uuid: client_uuid,
            status: status,
            global_settings: global_feature_settings
        }

        context "when client_settings is whitelisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

          it { is_expected.to be_truthy }
        end

        context "when client_settings is blacklisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

          it { is_expected.to be_falsey }
        end

        context "when client_settings is disabled_by_client" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:disabled_by_client] }

          it { is_expected.to be_falsey }
        end
      end

      context 'when global settings are enabled' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:enabled] }

        let!(:client_feature_settings) {
          create :client_feature_settings,
            client_uuid: client_uuid,
            status: status,
            global_settings: global_feature_settings
        }

        context "when client_settings is whitelisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

          it { is_expected.to be_truthy }
        end

        context "when client_settings is blacklisted" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

          it { is_expected.to be_falsey }
        end

        context "when client_settings is disabled_by_client" do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:disabled_by_client] }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#enable_global_setting!' do
    let(:feature_name) { 'foobar' }

    it 'creates global settings with a enabled status' do
      expect(client.enabled?(feature_name)).to be(false)
      result = client.enable_global_setting!(feature_name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(true)
    end

    it 'updates global settings with a enabled status' do
      global_feature_settings = create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:disabled]
      expect(client.enabled?(feature_name)).to be(false)
      result = client.enable_global_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(true)
    end
  end

  describe '#disable_global_setting!' do
    let(:feature_name) { 'foobar' }

    it 'creates global settings with a disabled status' do
      expect(client.enabled?(feature_name)).to be(false)
      result = client.disable_global_setting!(feature_name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end

    it 'updates global settings with a disabled status' do
      global_feature_settings = create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled]
      expect(client.enabled?(feature_name)).to be(true)
      result = client.disable_global_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end
  end

  describe '#disabled_hard_global_settings!' do
    let(:feature_name) { 'foobar' }

    it 'creates global settings with a disabled_hard status' do
      expect(client.enabled?(feature_name)).to be(false)
      result = client.disable_global_setting!(feature_name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end

    it 'updates global settings with a disabled_hard status' do
      global_feature_settings = create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled]
      expect(client.enabled?(feature_name)).to be(true)
      result = client.disable_global_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end
  end

  describe '#whitelist_client_setting!' do
    it 'creates client settings with a whitelisted status' do
      expect(client.enabled?(global_feature_settings.name)).to be(true)
      result = client.whitelist_client_setting!(global_feature_settings.name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(global_feature_settings.name)).to be(true)
    end

    it 'updates client settings with a whitelisted status' do
      create :client_feature_settings,
            client_uuid: client_uuid,
            status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
            global_settings: global_feature_settings

      expect(client.enabled?(feature_name)).to be(false)
      result = client.whitelist_client_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(true)
    end
  end

  describe '#blacklist_client_setting!' do
    it 'creates client settings with a blacklisted status' do
      expect(client.enabled?(global_feature_settings.name)).to be(true)
      result = client.blacklist_client_setting!(global_feature_settings.name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(global_feature_settings.name)).to be(false)
    end

    it 'updates client settings with a blacklisted status' do
      create :client_feature_settings,
            client_uuid: client_uuid,
            status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
            global_settings: global_feature_settings

      expect(client.enabled?(feature_name)).to be(true)
      result = client.blacklist_client_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end
  end

  describe '#disable_by_client_client_setting  !' do
    it 'creates client settings with a disabled_by_client status' do
      expect(client.enabled?(global_feature_settings.name)).to be(true)
      result = client.disable_by_client_client_setting!(global_feature_settings.name)

      expect(result[:success]).to be(true)
      expect(client.enabled?(global_feature_settings.name)).to be(false)
    end

    it 'updates client settings with a disabled_by_client status' do
      create :client_feature_settings,
            client_uuid: client_uuid,
            status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
            global_settings: global_feature_settings

      expect(client.enabled?(feature_name)).to be(true)
      result = client.disable_by_client_client_setting!(feature_name, extra_data: { custom_data: 'value' })

      expect(result[:success]).to be(true)
      expect(client.enabled?(feature_name)).to be(false)
    end
  end
end
