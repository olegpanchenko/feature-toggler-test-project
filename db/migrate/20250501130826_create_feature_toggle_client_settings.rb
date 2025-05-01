class CreateFeatureToggleClientSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :feature_toggle_client_settings do |t|
      t.integer :status, null: false
      t.string :client_uuid
      t.json :extra_data
      t.references :feature_toggle_settings, index: { name: 'index_feature_client_on_feature_toggle_settings' }
    end
 
    add_index :feature_toggle_client_settings, [:client_uuid, :feature_toggle_settings_id], name: 'index_feature_settings_on_feature_toggle_settings', unique: true
  end
 end
 