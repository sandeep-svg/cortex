class CreateChunks < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"

    create_table :chunks do |t|
      t.references :document, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, default: 0, null: false
      t.integer :token_count, default: 0, null: false
      t.vector :embedding, limit: 3072
      t.timestamps
    end
  end
end
