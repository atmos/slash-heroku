# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170105191210) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "commands", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "args"
    t.string   "application"
    t.string   "channel_id",    null: false
    t.string   "channel_name",  null: false
    t.string   "command",       null: false
    t.string   "command_text"
    t.string   "response_url",  null: false
    t.string   "subtask"
    t.string   "task"
    t.string   "team_id",       null: false
    t.string   "team_domain",   null: false
    t.uuid     "user_id"
    t.datetime "processed_at"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "slack_user_id"
  end

  create_table "message_actions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "value",        null: false
    t.string "callback_id",  null: false
    t.string "team_id",      null: false
    t.string "team_domain",  null: false
    t.string "channel_id",   null: false
    t.string "channel_name", null: false
    t.uuid   "user_id"
    t.string "message_ts",   null: false
    t.string "action_ts",    null: false
    t.string "response_url", null: false
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "enc_heroku_token"
    t.string   "enc_heroku_refresh_token"
    t.string   "heroku_uuid"
    t.string   "heroku_email"
    t.datetime "heroku_expires_at"
    t.string   "slack_user_id",            null: false
    t.string   "slack_user_name",          null: false
    t.string   "slack_team_id",            null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "enc_github_token"
    t.string   "github_login"
  end

end
