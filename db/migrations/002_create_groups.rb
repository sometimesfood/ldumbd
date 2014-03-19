Sequel.migration do
  change do
    create_table(:groups) do
      primary_key :id
      String      :name, size: 32, null: false, unique: true
      index       :name
    end
  end
end
