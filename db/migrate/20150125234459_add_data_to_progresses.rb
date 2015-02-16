class AddDataToProgresses < ActiveRecord::Migration
  def change
    add_column :progresses, :data, :text, null: true, default: nil
  end
end
