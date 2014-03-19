require_relative 'spec_helper'

require 'ldumbd/table_map'
require 'ldumbd/ldap_tree'
require 'ldumbd/operation'

class Ldumbd::Operation
  public :search_results
end

class ConnectionMock
  def opt
    Hash.new
  end
end

class MessageIDMock; end

def ldap_objects(sequel_objects)
  sequel_objects.map { |o| Ldumbd::TableMap.sequel_to_ldap_object(o) }
end

describe Ldumbd::Operation do
  before(:each) do
    @john = new_user('John Doe')
    @jane = new_user('Jane Doe')
    @no_group = Group.where(id: 65534, name: 'nogroup').first
    @all_group = Group.create(name: 'allusers')
    @all_group.add_user(@john)
    @all_group.add_user(@jane)

    @basedn = 'dc=example,dc=org'
    @root = {
      'dn_prefix' => '',
      'dc' => 'example',
      'objectClass' => %w{top domain}
    }
    @people = {
      'dn_prefix' => 'ou=People',
      'ou' => 'People',
      'objectClass' => %w{top organizationalUnit}
    }
    @groups = {
      'dn_prefix' => 'ou=Groups',
      'ou' => 'Groups',
      'objectClass' => %w{top organizationalUnit}
    }
    @operation = Ldumbd::Operation.new(ConnectionMock.new,
                                       MessageIDMock.new,
                                       Ldumbd::LdapTree.new(@basedn))
  end

  it 'should raise exceptions when using an invalid search scope' do
    proc do
      @operation.search_results(nil, 'InvalidScope', nil, nil)
    end.must_raise LDAP::ResultError::UnwillingToPerform
  end

  describe LDAP::Server::BaseObject do
    before(:each) do
      @scope = LDAP::Server::BaseObject
    end

    it 'should find users by dn' do
      filter = [:true]
      dn = "uid=#{@john.name},ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal ldap_objects([@john])
    end

    it 'should find organization units by dn' do
      filter = [:true]
      dn = "ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal [@people]
    end

    it 'should find the root object by dn' do
      filter = [:true]
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal [@root]
    end

    it 'should raise exceptions when searching for nonexistent objects' do
      filter = [:true]
      ["dc=non,dc=existent",
       "uid=nonexistent,ou=People,#{@basedn}"].each do |dn|
        proc do
          @operation.search_results(dn, @scope, nil, filter)
        end.must_raise LDAP::ResultError::NoSuchObject
      end
    end

    it 'should not return any objects when using unsatisfiable filters' do
      filter = [:eq, 'nonexistent_attribute', nil, 'nonexistent_value']
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal []
    end
  end

  describe LDAP::Server::SingleLevel do
    before(:each) do
      @scope = LDAP::Server::SingleLevel
    end

    it 'should retrieve the immediate children of an object' do
      filter = [:true]
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      subtree = [@people, @groups]
      results.must_equal_unordered subtree
    end

    it 'should retrieve all users via the People ou' do
      filter = [:true]
      dn = "ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      people_tree = [@john, @jane]
      results.must_equal_unordered ldap_objects(people_tree)
    end

    it 'should retrieve all users via the People ou when using a filter' do
      filter = [:eq, 'objectClass', nil, 'posixAccount']
      dn = "ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      people_tree = [@john, @jane]
      results.must_equal_unordered ldap_objects(people_tree)
    end

    it 'should raise exceptions when searching for nonexistent objects' do
      filter = [:true]
      ["dc=non,dc=existent",
       "uid=nonexistent,ou=People,#{@basedn}"].each do |dn|
        proc do
          @operation.search_results(dn, @scope, nil, filter)
        end.must_raise LDAP::ResultError::NoSuchObject
      end
    end

    it 'should not return any objects when using unsatisfiable filters' do
      filter = [:eq, 'nonexistent_attribute', nil, 'nonexistent_value']
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal []
    end
  end

  describe LDAP::Server::WholeSubtree do
    before(:each) do
      @scope = LDAP::Server::WholeSubtree
    end

    it 'should retrieve the whole tree via the basedn' do
      filter = [:true]
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      ldap_tree = [@root, @people, @john, @jane, @groups, @no_group, @all_group]
      results.must_equal_unordered ldap_objects(ldap_tree)
    end

    it 'should include the base object in the results when using filters' do
      filter = [:eq, 'uid', nil, @john.name]
      dn = "uid=#{@john.name},ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal ldap_objects([@john])
    end

    it 'should retrieve all users via the People ou' do
      filter = [:true]
      dn = "ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      people_tree = [@people, @john, @jane]
      results.must_equal_unordered ldap_objects(people_tree)
    end

    it 'should retrieve all users via the People ou when using a filter' do
      filter = [:eq, 'objectClass', nil, 'posixAccount']
      dn = "ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      people_tree = [@john, @jane]
      results.must_equal_unordered ldap_objects(people_tree)
    end

    it 'should retrieve single users by dn' do
      filter = [:true]
      dn = "uid=#{@john.name},ou=People,#{@basedn}"
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal ldap_objects([@john])
    end

    it 'should raise exceptions when searching for nonexistent objects' do
      filter = [:true]
      ["dc=non,dc=existent",
       "uid=nonexistent,ou=People,#{@basedn}"].each do |dn|
        proc do
          @operation.search_results(dn, @scope, nil, filter)
        end.must_raise LDAP::ResultError::NoSuchObject
      end
    end

    it 'should not return any objects when using unsatisfiable filters' do
      filter = [:eq, 'nonexistent_attribute', nil, 'nonexistent_value']
      dn = @basedn
      results = []
      @operation.search_results(dn, @scope, nil, filter) do |r|
        results << r
      end
      results.must_equal []
    end
  end

  describe 'search' do
    it 'should call send_SearchResultEntry' do
      filter = [:true]
      scope = LDAP::Server::BaseObject
      mock = MiniTest::Mock.new

      root_dn = @basedn
      root_avs = @root.reject { |k, v| k == 'dn_prefix' }
      john_dn = "uid=#{@john.name},ou=People,#{@basedn}"
      john_attrs = Ldumbd::TableMap.sequel_to_ldap_object(@john)
      john_avs = john_attrs.reject { |k, v| k == 'dn_prefix' }

      mock.expect(:send_SearchResultEntry, nil, [root_dn, root_avs])
      mock.expect(:send_SearchResultEntry, nil, [john_dn, john_avs])
      @operation.stub(:send_SearchResultEntry,
                      ->(dn, avs) { mock.send_SearchResultEntry(dn, avs) }) do
        @operation.search(root_dn, scope, nil, filter)
        @operation.search(john_dn, scope, nil, filter)
      end
    end
  end
end
