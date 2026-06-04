class CreateCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :campaigns do |t|
      t.string  :name,             null: false
      t.string  :slug,             null: false
      t.bigint  :owner_id,         null: false
      t.string  :status,           null: false, default: "setup"
      t.string  :files_path,       null: false
      t.boolean :world_configured,             default: false
      t.datetime :started_at

      t.timestamps
    end

    add_index :campaigns, :slug,     unique: true
    add_index :campaigns, :owner_id
    add_index :campaigns, :status
  end
end
