class CreateBooks < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE SEQUENCE books_serial_number_seq
        START WITH 1
        INCREMENT BY 1
        MINVALUE 1
        MAXVALUE 999999
        NO CYCLE;
    SQL

    create_table :books do |t|
      t.string :serial_number, null: false, limit: 6
      t.string :title, null: false
      t.string :author, null: false
      t.timestamps
    end

    add_index :books, :serial_number, unique: true
  end

  def down
    drop_table :books
    execute "DROP SEQUENCE IF EXISTS books_serial_number_seq;"
  end
end
