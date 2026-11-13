class CreateAssistantChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :assistant_challenges, id: :uuid do |t|
      t.references :user, type: :uuid, foreign_key: true
      t.string :shop_id, null: false
      t.string :ticket_digest, null: false
      t.string :email_digest, null: false
      t.string :code_digest, null: false
      t.string :auth_fingerprint
      t.jsonb :context, null: false, default: {}
      t.integer :attempts, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :consumed_at
      t.timestamps
    end
    add_index :assistant_challenges, :ticket_digest, unique: true
    add_index :assistant_challenges, [:shop_id, :email_digest, :created_at], name: 'assistant_challenges_email_window'
  end
end
