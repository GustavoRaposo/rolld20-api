class CreateCharacters < ActiveRecord::Migration[7.2]
  def change
    create_table :characters do |t|
      t.bigint  :campaign_id,      null: false
      t.bigint  :user_id,          null: false
      t.string  :name,             null: false
      t.string  :character_class,  null: false
      t.integer :level,            null: false, default: 1
      t.integer :current_xp,       null: false, default: 0
      t.boolean :level_up_pending,             default: false
      t.string  :files_path,       null: false

      t.timestamps
    end

    add_index :characters, :campaign_id
    add_index :characters, :user_id
    add_index :characters, [:campaign_id, :user_id], unique: true
  end
end
