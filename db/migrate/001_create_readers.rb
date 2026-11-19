class CreateReaders < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE SEQUENCE readers_card_number_seq
        START WITH 1
        INCREMENT BY 1
        MINVALUE 1
        MAXVALUE 999999
        NO CYCLE;
    SQL

    create_table :readers do |t|
      t.string :card_number, null: false, limit: 6
      t.string :full_name, null: false
      t.string :email, null: false
      t.timestamps
    end

    add_index :readers, :card_number, unique: true
    add_index :readers, :email, unique: true
  end

  def down
    drop_table :readers
    execute "DROP SEQUENCE IF EXISTS readers_card_number_seq;"
  end
end
