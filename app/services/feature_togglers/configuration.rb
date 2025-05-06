module FeatureTogglers
  module Configuration
    STATUSES = {
      global: {
        disabled: 1,
        disabled_hard: 2,
        enabled: 3
      },
      client: {
        whitelisted: 1,
        blacklisted: 2,
        disabled_by_client: 3
      }
    }
  end
end
