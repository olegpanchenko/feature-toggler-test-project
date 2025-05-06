# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureTogglers::Cache do
  let(:cache) { described_class.new }

  describe '#initialize' do
    it 'starts with nil global_features' do
      expect(cache.global_features).to be_nil
    end

    it 'starts with empty client_settings' do
      expect(cache.client_settings('any_feature')).to be_nil
    end
  end

  describe '#set_global_features' do
    let(:features) { %w[feature_a feature_b] }

    it 'sets global_features' do
      cache.set_global_features(features)
      expect(cache.global_features).to eq(features)
    end
  end

  describe '#set_client_settings and #client_settings' do
    let(:feature_name) { 'feature_x' }
    let(:settings) { { status: 'enabled' } }

    it 'sets and gets client settings by feature name' do
      cache.set_client_settings(feature_name, settings)
      expect(cache.client_settings(feature_name)).to eq(settings)
    end
  end

  describe '#clear' do
    before do
      cache.set_global_features(['some_feature'])
      cache.set_client_settings('feature_y', { status: 'disabled' })
    end

    it 'clears global_features and client_settings' do
      cache.clear
      expect(cache.global_features).to be_nil
      expect(cache.client_settings('feature_y')).to be_nil
    end
  end
end
