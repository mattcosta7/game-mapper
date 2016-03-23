class AddColumnsToUser < ActiveRecord::Migration
  def change
    add_column :users, :email, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :location, :string
    add_column :users, :description, :string
    add_column :users, :phone, :string
    add_column :users, :bio, :string
    add_column :users, :birthday, :string
    add_column :users, :age_range, :string
    add_column :users, :locale, :string
    add_column :users, :about, :string
  end
end
