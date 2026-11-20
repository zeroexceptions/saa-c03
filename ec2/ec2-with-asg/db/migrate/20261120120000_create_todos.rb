class CreateTodos < ActiveRecord::Migration[7.1]
  def change
    create_table :todos do |t|
      t.string :title, null: false
      t.text :details
      t.boolean :completed, null: false, default: false
      t.date :due_date
      t.timestamps
    end
    add_index :todos, :completed
    add_index :todos, :due_date
  end
end
