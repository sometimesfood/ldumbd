class User < Sequel::Model
  many_to_many :groups
end
