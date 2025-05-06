# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureTogglers::Cache do
  let(:cache) { described_class.new }

  describe '#initialize' do
    it 'starts with nil global_features and client_settings' do
      expect(cache.global_features).to be_nil
      expect(cache.client_settings).to be_nil
    end
  end

  describe '#set_global_features and #global_features' do
    it 'sets and retrieves global_features in a thread-safe way' do
      features = ['feature1', 'feature2']
      cache.set_global_features(features)
      expect(cache.global_features).to eq(features)
    end
  end

  describe '#set_client_settings and #client_settings' do
    it 'sets and retrieves client_settings in a thread-safe way' do
      settings = { 'status' => 'whitelist' }
      cache.set_client_settings(settings)
      expect(cache.client_settings).to eq(settings)
    end
  end

  describe '#clear' do
    it 'resets global_features and client_settings to nil' do
      cache.set_global_features(['something'])
      cache.set_client_settings({ 'status' => 'whitelist' })

      cache.clear

      expect(cache.global_features).to be_nil
      expect(cache.client_settings).to be_nil
    end
  end
end
