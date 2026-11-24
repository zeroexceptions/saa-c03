class AddTodosListIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :todos, %i[completed due_date created_at id],
      order: { completed: :asc, due_date: :asc, created_at: :desc, id: :desc },
      name: "index_todos_on_list_order", algorithm: :concurrently
  end
end
