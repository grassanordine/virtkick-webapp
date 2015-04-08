class AddPlansTable < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.integer 'price'
      t.string 'currency'
      t.string 'params'
      t.string 'period'

      t.index :price
      t.index :currency
      t.index :period
    end
  end
end
