class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :title
      t.string :content_type
      t.integer :file_size
      t.integer :word_count
      t.integer :chunk_count, default: 0, null: false
      t.string :status, default: "queued", null: false
      t.text :error
      t.datetime :processed_at
      t.timestamps
    end
  end
end
