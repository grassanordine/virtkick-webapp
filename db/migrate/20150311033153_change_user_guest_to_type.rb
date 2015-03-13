class ChangeUserGuestToType < ActiveRecord::Migration
  def change
    rename_column :users, :guest, :role
    change_column :users, :role, :string
  end
end
