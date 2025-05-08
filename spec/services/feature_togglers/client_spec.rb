require 'rails_helper'

RSpec.describe FeatureTogglers::Client, type: :model do
  let(:client_uuid) { '123' }
  let(:feature_name) { 'main_feature' }
  let(:extra_data) { {} }
  let(:client) { described_class.new(client_uuid: client_uuid) }
  let(:global_feature_setting) { create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled], extra_data: extra_data }

  describe '#enabled?' do
    subject { client.enabled?(feature_name) }

    context 'when global setting do not exist' do
      let(:feature_name) { 'new_feature' }

      it { is_expected.to be_falsey }
    end

    context 'when global setting exists' do
      before do
        global_feature_setting
        global_feature_setting.update!(status: global_status)
      end

      context 'when global setting is disabled_hard' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:disabled_hard] }

        it { is_expected.to be_falsey }
      end

      context 'when global setting is disabled' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:disabled] }
        let!(:client_feature_settings) {
          create :client_feature_settings,
            client_uuid: client_uuid,
            status: status,
            global_settings: global_feature_setting
        }

        context 'when client_setting is whitelisted' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

          it { is_expected.to be_truthy }
        end

        context 'when client_setting is blacklisted' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

          it { is_expected.to be_falsey }
        end

        context 'when client_setting is disabled_by_client' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:disabled_by_client] }

          it { is_expected.to be_falsey }
        end
      end

      context 'when global setting is enabled' do
        let(:global_status) { FeatureTogglers::GlobalSettings::STATUS[:enabled] }

        let!(:client_feature_settings) {
          create :client_feature_settings,
            client_uuid: client_uuid,
            status: status,
            global_settings: global_feature_setting
        }

        context 'when client_setting is whitelisted' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

          it { is_expected.to be_truthy }
        end

        context 'when client_setting is blacklisted' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

          it { is_expected.to be_falsey }
        end

        context 'when client_setting is disabled_by_client' do
          let(:status) { FeatureTogglers::ClientSettings::STATUS[:disabled_by_client] }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#enable_global_setting!' do
    let(:feature_name) { 'foobar' }

    shared_examples 'a successful enable' do
      it 'returns success and enables the feature' do
        expect(client.enabled?(feature_name)).to be(before_disabled)
        result = client.enable_global_setting!(feature_name, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature_name)).to be(true)
        expect(global_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no global setting exists' do
      let(:before_disabled) { false }
      let(:global_setting) { FeatureTogglers::GlobalSettings.find_by(name: feature_name) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful enable'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { false }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:disabled],
               extra_data: expected_extra_data
      end

      include_examples 'a successful enable'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { false }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:disabled],
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful enable'
    end
  end

  describe '#disable_global_setting!' do
    let(:feature_name) { 'foobar' }

    shared_examples 'a successful disable' do
      it 'returns success and disables the feature' do
        expect(client.enabled?(feature_name)).to be(before_disabled)
        result = client.disable_global_setting!(feature_name, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature_name)).to be(false)
        expect(global_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no global setting exists' do
      let(:before_disabled) { false }
      let(:global_setting) { FeatureTogglers::GlobalSettings.find_by(name: feature_name) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful disable'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { true }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:enabled],
               extra_data: expected_extra_data
      end

      include_examples 'a successful disable'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { true }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:enabled],
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful disable'
    end
  end

  describe '#disable_hard_global_setting!' do
    let(:feature_name) { 'foobar' }

    shared_examples 'a successful hard disable' do
      it 'returns success and disables the feature' do
        expect(client.enabled?(feature_name)).to be(before_disabled)
        result = client.disable_hard_global_setting!(feature_name, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature_name)).to be(false)
        expect(global_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no global setting exists' do
      let(:before_disabled) { false }
      let(:global_setting) { FeatureTogglers::GlobalSettings.find_by(name: feature_name) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful hard disable'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { true }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:enabled],
               extra_data: expected_extra_data
      end

      include_examples 'a successful hard disable'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { true }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:global_setting) do
        create :global_feature_settings, name: feature_name,
               status: FeatureTogglers::GlobalSettings::STATUS[:enabled],
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful hard disable'
    end
  end

  describe '#whitelist_client_setting!' do
    let(:feature) { global_feature_setting.name }

    shared_examples 'a successful whitelist' do
      it 'returns success and whitelist the feature' do
        expect(client.enabled?(feature)).to be(before_disabled)
        result = client.whitelist_client_setting!(feature, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature)).to be(true)
        expect(client_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no client setting exists' do
      let(:before_disabled) { true }
      let(:client_setting) { FeatureTogglers::ClientSettings.find_by(client_uuid: client_uuid) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful whitelist'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { false }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
               global_settings: global_feature_setting,
               extra_data: expected_extra_data
      end

      include_examples 'a successful whitelist'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { false }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:blacklisted],
               global_settings: global_feature_setting,
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful whitelist'
    end
  end

  describe '#blacklist_client_setting!' do
    let(:feature) { global_feature_setting.name }

    shared_examples 'a successful blacklist' do
      it 'returns success and blacklist the feature' do
        expect(client.enabled?(feature)).to be(before_disabled)
        result = client.blacklist_client_setting!(feature, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature)).to be(false)
        expect(client_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no client setting exists' do
      let(:before_disabled) { true }
      let(:client_setting) { FeatureTogglers::ClientSettings.find_by(client_uuid: client_uuid) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful blacklist'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { true }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
               global_settings: global_feature_setting,
               extra_data: expected_extra_data
      end

      include_examples 'a successful blacklist'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { true }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
               global_settings: global_feature_setting,
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful blacklist'
    end
  end

  describe '#disable_by_client_client_setting!' do
    let(:feature) { global_feature_setting.name }

    shared_examples 'a successful disable by client' do
      it 'returns success and disable by client the feature' do
        expect(client.enabled?(feature)).to be(before_disabled)
        result = client.disable_by_client_client_setting!(feature, extra_data: input_extra_data)

        expect(result[:success]).to be(true)
        expect(client.enabled?(feature)).to be(false)
        expect(client_setting.reload.extra_data).to eq(expected_extra_data)
      end
    end

    context 'when no client setting exists' do
      let(:before_disabled) { true }
      let(:client_setting) { FeatureTogglers::ClientSettings.find_by(client_uuid: client_uuid) }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { nil }

      include_examples 'a successful disable by client'
    end

    context 'when a global setting exists with custom extra_data' do
      let(:before_disabled) { true }
      let(:input_extra_data) { nil }
      let(:expected_extra_data) { { 'custom_data' => 'value' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
               global_settings: global_feature_setting,
               extra_data: expected_extra_data
      end

      include_examples 'a successful disable by client'
    end

    context 'when overriding extra_data during disable' do
      let(:before_disabled) { true }
      let(:input_extra_data) { { custom_data: 'bar' } }
      let(:expected_extra_data) { { 'custom_data' => 'bar' } }

      let!(:client_setting) do
        create :client_feature_settings, client_uuid: client_uuid,
               status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
               global_settings: global_feature_setting,
               extra_data: { custom_data: 'foo' }
      end

      include_examples 'a successful disable by client'
    end
  end

  context 'Rollout strategy' do
    [5, 10, 25].each do |percentage|
      context "at #{percentage}%" do
        let(:rollout_percentage) { percentage }
        let(:extra_data) {
          {
            rollout_percentage: rollout_percentage
          }
        }
        let!(:global_feature_setting) { create :global_feature_settings, name: feature_name, status: FeatureTogglers::GlobalSettings::STATUS[:enabled], extra_data: extra_data }

        context 'when client_setting is present' do
          subject { client.enabled?(feature_name) }

          let!(:client_feature_settings) {
            create :client_feature_settings,
              client_uuid: client_uuid,
              status: FeatureTogglers::ClientSettings::STATUS[:whitelisted],
              global_settings: global_feature_setting
          }

          it 'does not create a new client_setting record' do
            expect {
              subject
            }.not_to change(FeatureTogglers::ClientSettings, :count)
          end
        end

        context 'when client_setting is blank' do
          subject { client.enabled?(feature_name) }

          it 'creates a new client_setting record with whitelisted or blacklisted status' do
            expect {
              subject
            }.to change(FeatureTogglers::ClientSettings, :count).by(1)

            setting = FeatureTogglers::ClientSettings.last
            expect(setting.client_uuid).to eq(client_uuid)
            expect(setting.feature_toggle_settings_id).to eq(global_feature_setting.id)
            expect(setting.status).to(
              satisfy { |status|
                [
                  FeatureTogglers::ClientSettings::STATUS[:whitelisted],
                  FeatureTogglers::ClientSettings::STATUS[:blacklisted]
                ].include?(status)
              }
            )
            expect(setting.generated_by_rollout?).to be(true).or be_truthy
          end

          it 'assigns whitelisted clients based on rollout percentage' do
            whitelist_count = 0
            test_count = 500

            test_count.times do |i|
              client_uuid = "test-client-#{i}"
              client = FeatureTogglers::Client.new(client_uuid: client_uuid)
              client.enabled?(feature_name)

              setting = FeatureTogglers::ClientSettings.find_by(client_uuid: client_uuid)
              expect(setting).not_to be_nil

              if setting.status == FeatureTogglers::ClientSettings::STATUS[:whitelisted]
                whitelist_count += 1
              end
            end

            actual_percentage = (whitelist_count.to_f / test_count * 100).round

            expect(actual_percentage).to be_within(5).of(rollout_percentage)
          end
        end
      end
    end

    context 'increase rollout_percentage' do
      let(:rollout_percentage) { 5 }
      let(:new_rollout_percentage) { 25 }
      let(:test_count) { 500 }

      before do
        # persist global_feature_settings
        global_feature_setting
        # create 5 whitelisted and 95 blacklisted client_settings
        clients_count = 100
        clients_count.times do |i|
          status = i < rollout_percentage ? FeatureTogglers::Configuration::STATUSES[:client][:whitelisted] : FeatureTogglers::Configuration::STATUSES[:client][:blacklisted]
          create(:client_feature_settings,
            client_uuid: "test-client-#{i}",
            status: status,
            global_settings: global_feature_setting,
            extra_data: {
              'generated_by_rollout' => true,
              'assigned_by_percentage' => rollout_percentage
            }
          )
        end
        # increase rollout_percentage
        global_feature_setting.update!(extra_data: {rollout_percentage: new_rollout_percentage})
        # collect existing whitelisted clients uuids
        @whitelisted_clients_uuids = FeatureTogglers::ClientSettings.where(status: FeatureTogglers::ClientSettings::STATUS[:whitelisted]).pluck(:client_uuid)

        test_count.times do |i|
          client = FeatureTogglers::Client.new(client_uuid: "test-client-#{i}")
          client.enabled?(feature_name)
        end

      end

      it 'retains previously whitelisted clients when increasing rollout percentage' do
        statuses = FeatureTogglers::ClientSettings.where(client_uuid: @whitelisted_clients_uuids).pluck(:status).uniq
        expect(statuses.size).to eq(1)
        expect(statuses.first).to eq(FeatureTogglers::ClientSettings::STATUS[:whitelisted])
      end

      it 'assigns whitelisted clients based on rollout percentage' do
        total_count = FeatureTogglers::ClientSettings.count
        whitelist_count = FeatureTogglers::ClientSettings.where(status: FeatureTogglers::ClientSettings::STATUS[:whitelisted]).count
        actual_percentage = (whitelist_count.to_f / total_count * 100).round

        expect(actual_percentage).to be_within(10).of(new_rollout_percentage)
      end
    end

    context 'decrease rollout_percentage' do
      let(:rollout_percentage) { 25 }
      let(:new_rollout_percentage) { 5 }
      let(:test_count) { 500 }

      before do
        # persist global_feature_settings
        global_feature_setting
        # create 25 whitelisted and 75 blacklisted client_settings
        clients_count = 100
        clients_count.times do |i|
          status = i < rollout_percentage ? FeatureTogglers::Configuration::STATUSES[:client][:whitelisted] : FeatureTogglers::Configuration::STATUSES[:client][:blacklisted]
          create(:client_feature_settings,
              client_uuid: "test-client-#{i}",
              status: status,
              global_settings: global_feature_setting,
              extra_data: {
                'generated_by_rollout' => true,
                'assigned_by_percentage' => rollout_percentage
              }
            )
        end
        # decrease rollout_percentage
        global_feature_setting.update!(extra_data: {rollout_percentage: new_rollout_percentage})

        # collect existing whitelisted clients uuids
        @whitelisted_clients_uuids = FeatureTogglers::ClientSettings.where(status: FeatureTogglers::ClientSettings::STATUS[:whitelisted]).pluck(:client_uuid)

        test_count.times do |i|
          client = FeatureTogglers::Client.new(client_uuid: "test-client-#{i}")
          client.enabled?(feature_name)
        end
      end

      it 'retains previously whitelisted clients when decreasing rollout percentage' do
        statuses = FeatureTogglers::ClientSettings.where(client_uuid: @whitelisted_clients_uuids).pluck(:status).uniq
        expect(statuses.size).to eq(1)
        expect(statuses.first).to eq(FeatureTogglers::ClientSettings::STATUS[:whitelisted])
      end

      it 'assigns whitelisted clients based on rollout percentage' do
        total_count = FeatureTogglers::ClientSettings.count
        whitelist_count = FeatureTogglers::ClientSettings.where(status: FeatureTogglers::ClientSettings::STATUS[:whitelisted]).count
        actual_percentage = (whitelist_count.to_f / total_count * 100).round

        expect(actual_percentage).to be_within(10).of(new_rollout_percentage)
      end
    end
  end
end
