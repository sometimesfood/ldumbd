Sequel.migration do
  nogroup_gid = 65534

  up do
    self[:groups].insert(id: nogroup_gid, name: 'nogroup')
    alter_table(:users) do
      add_foreign_key :group_id, :groups, null: false, default: nogroup_gid
      # MySQL automatically adds indexes for foreign key columns
      add_index :group_id unless DB.database_type == :mysql
    end
  end

  down do
    alter_table(:users) do
      drop_index :group_id unless DB.database_type == :mysql
      drop_foreign_key :group_id
    end
    self[:groups].where(id: nogroup_gid).delete
  end
end
