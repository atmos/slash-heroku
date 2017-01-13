class RemoveNaclColumns < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :nacl_enc_github_token
    remove_column :users, :nacl_enc_heroku_token
    remove_column :users, :nacl_enc_heroku_refresh_token

    User.all.each do |user|
      user.heroku_token = nil
      user.github_token = nil
      user.save
    end
  end
end
