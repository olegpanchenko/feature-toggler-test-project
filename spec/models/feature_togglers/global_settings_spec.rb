require 'rails_helper'

RSpec.describe FeatureTogglers::GlobalSettings, type: :model do
  let(:global_settings) { build(:feature_togglers_global_settings) }

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'uniqueness validation' do
      before { create(:feature_togglers_global_settings, name: 'test_feature') }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

    it 'validates status inclusion' do
      valid_statuses = FeatureTogglers::GlobalSettings::STATUS.values
      expect(global_settings).to validate_inclusion_of(:status).in_array(valid_statuses)
    end
  end

  describe 'associations' do
    it { should have_many(:client_settings).class_name('FeatureTogglers::ClientSettings') }
    it { should have_many(:client_settings).dependent(:destroy) }
  end

  describe 'status methods' do
    let(:global_settings) { create(:feature_togglers_global_settings) }

    context 'when disabled_hard' do
      before { global_settings.status = FeatureTogglers::GlobalSettings::STATUS[:disabled_hard] }

      it { expect(global_settings.disabled_hard?).to be true }
      it { expect(global_settings.disabled?).to be false }
      it { expect(global_settings.enabled?).to be false }
    end

    context 'when disabled' do
      before { global_settings.status = FeatureTogglers::GlobalSettings::STATUS[:disabled] }

      it { expect(global_settings.disabled?).to be true }
      it { expect(global_settings.disabled_hard?).to be false }
      it { expect(global_settings.enabled?).to be false }
    end

    context 'when enabled' do
      before { global_settings.status = FeatureTogglers::GlobalSettings::STATUS[:enabled] }

      it { expect(global_settings.enabled?).to be true }
      it { expect(global_settings.disabled?).to be false }
      it { expect(global_settings.disabled_hard?).to be false }
    end
  end

  describe '.update_resource' do
    let(:global_settings) { create(:feature_togglers_global_settings) }
    let(:new_status) { FeatureTogglers::GlobalSettings::STATUS[:enabled] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'updates the resource successfully' do
      result = described_class.update_resource(global_settings.id, new_status, extra_data)
      expect(result[:success]).to be true
      global_settings.reload
      expect(global_settings.status).to eq(new_status)
      expect(global_settings.extra_data).to eq(extra_data)
    end

    context 'when update fails' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.update_resource(global_settings.id, new_status, extra_data)
        expect(result[:success]).to be false
      end
    end
  end

  describe '.create_resource' do
    let(:name) { 'test_feature' }
    let(:status) { FeatureTogglers::GlobalSettings::STATUS[:enabled] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'creates a new resource successfully' do
      result = described_class.create_resource(name, status, extra_data)
      expect(result[:success]).to be true
      expect(described_class.last.name).to eq(name)
      expect(described_class.last.status).to eq(status)
      expect(described_class.last.extra_data).to eq(extra_data)
    end

    context 'when creation fails' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.create_resource(name, status, extra_data)
        expect(result[:success]).to be false
      end
    end
  end

  describe '.save_resource' do
    let(:global_settings) { build(:feature_togglers_global_settings) }
    let(:status) { FeatureTogglers::GlobalSettings::STATUS[:enabled] }
    let(:extra_data) { { 'key' => 'value' } }

    it 'saves the resource successfully' do
      result = described_class.save_resource(global_settings, status, extra_data)
      expect(result[:success]).to be true
      expect(global_settings.status).to eq(status)
      expect(global_settings.extra_data).to eq(extra_data)
    end

    context 'when save fails' do
      before do
        allow(global_settings).to receive(:save).and_return(false)
      end

      it 'returns error response' do
        result = described_class.save_resource(global_settings, status, extra_data)
        expect(result[:success]).to be false
      end
    end

    context 'when extra_data is empty' do
      it 'sets extra_data to nil' do
        result = described_class.save_resource(global_settings, status, {})
        expect(result[:success]).to be true
        expect(global_settings.extra_data).to be {}
      end
    end
  end
end
