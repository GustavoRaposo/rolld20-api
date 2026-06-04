class CreateWorldLoreEmbeddings < ActiveRecord::Migration[7.2]
  def change
    create_table :world_lore_embeddings do |t|
      t.bigint :campaign_id, null: false
      t.text   :content,     null: false
      t.string :chunk_id,    null: false
      t.column :embedding,   :vector, limit: 1536

      t.datetime :created_at, null: false
    end

    add_index :world_lore_embeddings, :campaign_id
    add_index :world_lore_embeddings, [:campaign_id, :chunk_id], unique: true
  end
end
