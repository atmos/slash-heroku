class RenameActionsToMessageActions < ActiveRecord::Migration[5.0]
  def change
    rename_table :actions, :message_actions
  end
end
