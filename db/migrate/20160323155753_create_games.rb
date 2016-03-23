class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :address
      t.string :city
      t.string :state
      t.float :latitude
      t.float :longitude
      t.integer :sport
      t.integer :skill_level

      t.timestamps null: false
    end
  end
end
