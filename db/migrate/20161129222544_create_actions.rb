class CreateActions < ActiveRecord::Migration[5.0]
  def change
    create_table :actions, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :value,        null: false
      t.string :callback_id,  null: false
      t.string :team_id,      null: false
      t.string :team_domain,  null: false
      t.string :channel_id, null: false
      t.string :channel_name, null: false
      t.uuid   :user_id
      t.string :message_ts,   null: false
      t.string :action_ts,    null: false
      t.string :response_url, null: false
    end
  end
end
