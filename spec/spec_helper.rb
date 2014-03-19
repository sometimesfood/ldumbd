require 'minitest/autorun'
require 'yaml'
require 'sequel'

DATABASE_URL = ENV['DATABASE_URL'] || 'sqlite://ldumbd-test.sqlite3'
DB = Sequel.connect(DATABASE_URL)

require 'ldumbd/user'
require 'ldumbd/group'

class MiniTest::Spec
  before :each do
    @db_transaction = Fiber.new do
      DB.transaction(savepoint: true, rollback: :always) { Fiber.yield }
    end
    @db_transaction.resume
  end

  after :each do
    @db_transaction.resume
  end
end

def new_user(realname)
  name = realname.downcase.gsub(' ', '')
  homedir = "/home/#{name}"
  User.create(name: name,
              homedir: homedir,
              realname: realname)
end

module MiniTest::Assertions
  def assert_equal_unordered(a, b, msg = nil)
    msg ||= "Expected #{mu_pp(a)} to be equivalent to #{mu_pp(b)}"
    freq_a = a.inject(Hash.new(0)) { |h, v| h[v] += 1; h }
    freq_b = b.inject(Hash.new(0)) { |h, v| h[v] += 1; h }
    assert(freq_a == freq_b, msg)
  end
end

Array.infect_an_assertion :assert_equal_unordered, :must_equal_unordered
