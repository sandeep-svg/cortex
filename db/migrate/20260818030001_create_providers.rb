class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :api_key, null: false, default: ""
      t.string :base_url
      t.string :api_version
      t.string :chat_model
      t.string :embedding_model
      t.integer :embedding_dimensions, default: 1536
      t.boolean :enabled, default: true, null: false
      t.boolean :active, default: false, null: false
      t.string :notes
      t.timestamps
    end

    add_index :providers, :slug, unique: true
  end
end
