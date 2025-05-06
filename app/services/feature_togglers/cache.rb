module FeatureTogglers
  class Cache
    attr_reader :global_features

    def initialize
      @global_features = nil
      @client_settings = {}
      @mutex = Mutex.new
    end

    def set_global_features(features)
      @mutex.synchronize { @global_features = features }
    end

    def global_features
      @mutex.synchronize { @global_features }
    end

    def global_features=(features)
      set_global_features(features)
    end

    def client_settings(feature_name)
      @mutex.synchronize { @client_settings[feature_name] }
    end

    def set_client_settings(feature_name, settings)
      @mutex.synchronize { @client_settings[feature_name] = settings }
    end

    def clear
      @mutex.synchronize do
        @global_features = nil
        @client_settings = {}
      end
    end
  end
end
