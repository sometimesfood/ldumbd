Sequel.migration do
  change do
    create_table(:groups_users) do
      foreign_key :group_id, :groups, null: false
      foreign_key :user_id, :users, null: false
      primary_key [:group_id, :user_id]
      index :user_id
    end
  end
end
