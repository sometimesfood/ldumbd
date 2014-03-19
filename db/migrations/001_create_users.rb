Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String      :name,     size:  32, null: false, unique: true
      String      :realname, size:  64, null: false, default: ''
      String      :shell,    size:  32, null: false, default: '/bin/false'
      String      :homedir,  size: 128, null: false
      index       :name
    end
  end
end
