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
```

## Usage

### Basic Usage

```ruby
# Check if a feature is enabled for a client
client = FeatureTogglers::Client.new(client_uuid: 'client123')
if client.enabled?(feature_name)
  # Feature is enabled
else
  # Feature is disabled
end
```

### Managing Global Settings

```ruby
# Enable a feature globally
client.enable_global_settings!(feature_name)

# Disable a feature globally
client.disable_global_settings!(feature_name)

# Hard disable a feature globally
client.disable_hard_global_settings!(feature_name)
```

### Managing Client Settings

```ruby
# Whitelist a client for a feature
client.whitelist_client_settings!(feature_name)

# Blacklist a client from a feature
client.blacklist_client_settings!(feature_name)

# Disable a feature for a specific client
client.disable_by_client_client_settings!(feature_name)
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
