# FeatureTogglers

A flexible and efficient feature toggle system for Ruby on Rails applications.

## Overview

FeatureTogglers provides a robust way to manage feature flags in your application, allowing you to:

- Enable/disable features globally
- Control feature access per client
- Store additional configuration data
- Cache feature states for better performance

## Installation

Add to your Gemfile:

```ruby
gem 'feature_togglers'
```

Then run:

```bash
bundle install
```

## Configuration

The system uses a simple configuration setup:

```ruby
module FeatureTogglers
  module Configuration
    def self.statuses
      {
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
end
```

## Usage

### Basic Usage

```ruby
# Check if a feature is enabled for a client
client = FeatureTogglers::Client.new(feature_name: 'my_feature', client_uuid: 'client123')
if client.can_use?
  # Feature is enabled
else
  # Feature is disabled
end
```

### Managing Global Settings

```ruby
# Enable a feature globally
client.enabled_global_settings!

# Disable a feature globally
client.disabled_global_settings!

# Hard disable a feature globally
client.disabled_hard_global_settings!
```

### Managing Client Settings

```ruby
# Whitelist a client for a feature
client.whitelisted_client_settings!

# Blacklist a client from a feature
client.blacklisted_client_settings!

# Disable a feature for a specific client
client.disabled_by_client_client_settings!
```

### Adding Extra Data

```ruby
# Add extra configuration data
client.enabled_global_settings!(extra_data: {
  'enabled_for_organizations_newer_than_integer_date' => Time.now.to_i
})
```

## Status Types

### Global Statuses

- `disabled` (1): Feature is disabled but can be enabled for specific clients
- `disabled_hard` (2): Feature is completely disabled for all clients
- `enabled` (3): Feature is enabled for all clients unless specifically disabled

### Client Statuses

- `whitelisted` (1): Client has access to the feature
- `blacklisted` (2): Client is explicitly denied access
- `disabled_by_client` (3): Client has disabled the feature for themselves
