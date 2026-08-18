class CreateQueries < ActiveRecord::Migration[8.1]
  def change
    create_table :queries do |t|
      t.text :question, null: false
      t.text :answer
      t.references :provider, null: true, foreign_key: true
      t.references :document, null: true, foreign_key: true
      t.string :model
      t.string :status, default: "processing", null: false
      t.integer :prompt_tokens
      t.integer :completion_tokens
      t.integer :latency_ms
      t.jsonb :sources, default: []
      t.timestamps
    end
  end
end
