class AddTextReminderToUsers < ActiveRecord::Migration
  def change
    add_column :users, :text_reminder, :boolean, default: false
  end
end
