class CreateCampaignMemories < ActiveRecord::Migration[7.2]
  def change
    enable_extension "vector"

    create_table :campaign_memories do |t|
      t.bigint  :campaign_id,  null: false
      t.string  :memory_type,  null: false
      t.string  :entity_name
      t.string  :aspect
      t.text    :summary,      null: false
      t.integer :importance,               default: 1
      t.string  :chapter_id
      t.integer :turn_number
      t.column  :embedding,    :vector, limit: 1536

      t.datetime :created_at,  null: false
    end

    add_index :campaign_memories, :campaign_id
    add_index :campaign_memories, [:campaign_id, :memory_type]
    add_index :campaign_memories, [:campaign_id, :entity_name]
    add_index :campaign_memories, [:campaign_id, :importance]
  end
end
