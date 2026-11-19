class CreateLoans < ActiveRecord::Migration[8.1]
  def up
    create_table :loans do |t|
      t.references :book, null: false, foreign_key: true
      t.references :reader, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.datetime :due_at, null: false
      t.datetime :returned_at
      t.timestamps
    end
    add_index :loans, :due_at
  end
end
