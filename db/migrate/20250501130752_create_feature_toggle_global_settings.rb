class CreateFeatureToggleGlobalSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :feature_toggle_global_settings do |t|
      t.integer :status, null: false
      t.string :name, null: false, unique: true
      t.json :extra_data
    end
 
    add_index :feature_toggle_global_settings, :name, unique: true
  end
 end
 