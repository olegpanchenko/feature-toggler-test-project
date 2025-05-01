require 'rails_helper'

RSpec.describe FeatureTogglers::ClientSettings, type: :model do
  let(:global_settings) { create(:feature_togglers_global_settings) }
  let(:client_settings) { build(:feature_togglers_client_settings, global_settings: global_settings) }

  describe 'validations' do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:client_uuid) }
    it { should validate_presence_of(:feature_toggle_settings_id) }

    describe 'uniqueness validation' do
      before do
        create(:feature_togglers_client_settings,
               client_uuid: 'test-uuid',
               global_settings: global_settings,
               status: FeatureTogglers::ClientSettings::STATUS[:whitelisted])
      end

      it { should validate_uniqueness_of(:client_uuid).scoped_to(:feature_toggle_settings_id).case_insensitive }
    end

    it 'validates status inclusion' do
      valid_statuses = FeatureTogglers::ClientSettings::STATUS.values
      expect(client_settings).to validate_inclusion_of(:status).in_array(valid_statuses)
    end
  end

  describe 'associations' do
    it { should belong_to(:global_settings).class_name('FeatureTogglers::GlobalSettings') }
  end

  describe 'status methods' do
    let(:client_settings) { create(:feature_togglers_client_settings, global_settings: global_settings) }

    context 'when whitelisted' do
      before { client_settings.status = FeatureTogglers::ClientSettings::STATUS[:whitelisted] }

      it { expect(client_settings.whitelisted?).to be true }
      it { expect(client_settings.blacklisted?).to be false }
      it { expect(client_settings.disabled_by_client?).to be false }
    end

    context 'when blacklisted' do
      before { client_settings.status = FeatureTogglers::ClientSettings::STATUS[:blacklisted] }

      it { expect(client_settings.blacklisted?).to be true }
      it { expect(client_settings.whitelisted?).to be false }
      it { expect(client_settings.disabled_by_client?).to be false }
    end

    context 'when disabled by client' do
      before { client_settings.status = FeatureTogglers::ClientSettings::STATUS[:disabled_by_client] }

      it { expect(client_settings.disabled_by_client?).to be true }
      it { expect(client_settings.whitelisted?).to be false }
      it { expect(client_settings.blacklisted?).to be false }
    end
  end

  describe '.update_resource' do
    let(:client_settings) { create(:feature_togglers_client_settings, global_settings: global_settings) }
    let(:new_status) { FeatureTogglers::ClientSettings::STATUS[:blacklisted] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'updates the resource successfully' do
      result = described_class.update_resource(client_settings.id, new_status, extra_data)
      expect(result[:success]).to be true
      client_settings.reload
      expect(client_settings.status).to eq(new_status)
      expect(client_settings.extra_data).to eq(extra_data)
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.update_resource(client_settings.id, new_status, extra_data)
        expect(result[:success]).to be false
      end
    end
  end

  describe '.create_resource' do
    let(:client_uuid) { SecureRandom.uuid }
    let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'creates a new resource successfully' do
      result = described_class.create_resource(global_settings.id, client_uuid, status, extra_data)
      expect(result[:success]).to be true
      expect(described_class.last.client_uuid).to eq(client_uuid)
      expect(described_class.last.status).to eq(status)
      expect(described_class.last.extra_data).to eq(extra_data)
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.create_resource(global_settings.id, client_uuid, status, extra_data)
        expect(result[:success]).to be false
      end
    end
  end

  describe '.save_resource' do
    let(:client_settings) { build(:feature_togglers_client_settings, global_settings: global_settings) }
    let(:status) { FeatureTogglers::ClientSettings::STATUS[:whitelisted] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'saves the resource successfully' do
      result = described_class.save_resource(client_settings, status, extra_data)
      expect(result[:success]).to be true
      expect(client_settings.status).to eq(status)
      expect(client_settings.extra_data).to eq(extra_data)
    end

    context 'when save fails' do
      before do
        allow(client_settings).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.save_resource(client_settings, status, extra_data)
        expect(result[:success]).to be false
      end
    end

    context 'when extra_data is empty' do
      it 'sets extra_data to nil' do
        result = described_class.save_resource(client_settings, status, {})
        expect(result[:success]).to be true
        expect(client_settings.extra_data).to be {}
      end
    end
  end
end
