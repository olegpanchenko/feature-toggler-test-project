module FeatureTogglers
  class Cache
    def initialize
      @global_features = nil
      @client_settings = nil
      @mutex = Mutex.new
    end

    def set_global_features(features)
      @mutex.synchronize { @global_features = features }
    end

    def global_features
      @mutex.synchronize { @global_features }
    end

    def set_client_settings(settings)
      @mutex.synchronize { @client_settings = settings }
    end

    def client_settings
      @mutex.synchronize { @client_settings }
    end

    def clear!
      @mutex.synchronize do
        @global_features = nil
        @client_settings = nil
      end
    end
  end
end
