class CreateAssistantDelegations < ActiveRecord::Migration[8.0]
  def change
    # Set only by the future verified-email browser flow; welcome mail is not verification.
    add_column :users, :assistant_email_verified_at, :datetime
    create_table :assistant_delegations, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :shop_id, null: false
      t.string :audience, null: false
      t.jsonb :context, null: false
      t.string :code_digest, null: false
      t.string :grant_digest
      t.datetime :issued_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :consented_at, null: false
      t.string :policy_version, null: false
      t.datetime :consumed_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :assistant_delegations, :code_digest, unique: true
    add_index :assistant_delegations, :grant_digest, unique: true
  end
end
