class AddDataToProgresses < ActiveRecord::Migration
  def change
    add_column :progresses, :data, :json, null: true, default: nil
  end
end
