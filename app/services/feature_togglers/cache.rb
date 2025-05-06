module FeatureTogglers
  class Cache
    attr_reader :global_features

    def initialize
      @global_features = nil
      @client_settings = {}
    end

    def set_global_features(features)
      @global_features = features
    end

    def client_settings(feature_name)
      @client_settings[feature_name]
    end

    def set_client_settings(feature_name, settings)
      @client_settings[feature_name] = settings
    end

    def clear
      @global_features = nil
      @client_settings = {}
    end
  end
end
