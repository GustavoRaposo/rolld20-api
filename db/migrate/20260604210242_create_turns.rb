class CreateTurns < ActiveRecord::Migration[7.2]
  def change
    create_table :turns do |t|
      t.bigint  :campaign_id,      null: false
      t.bigint  :character_id,     null: false
      t.integer :turn_number,      null: false
      t.text    :player_action,    null: false
      t.text    :gm_narrative,     null: false
      t.jsonb   :mechanic_result
      t.jsonb   :game_events,                  default: []

      t.datetime :created_at,      null: false
    end

    add_index :turns, :campaign_id
    add_index :turns, :character_id
    add_index :turns, [:campaign_id, :turn_number], unique: true
    add_index :turns, :game_events, using: :gin
  end
end
