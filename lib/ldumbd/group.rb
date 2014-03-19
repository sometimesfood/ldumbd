class Group < Sequel::Model
  many_to_many :users
end
