require_relative 'spec_helper'

require 'ldumbd/filter_converter'

describe Ldumbd::FilterConverter do
  before(:each) do
    @john = new_user('John Doe')
    @jane = new_user('Jane Doe')
    @all_group = Group.create(name: 'allusers')
    @all_group.add_user(@john)
    @all_group.add_user(@jane)
  end

  it 'should process :true filters' do
    filter = [:true]
    user_query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    group_query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    users = User.where(user_query)
    groups = Group.where(group_query)
    users.count.must_equal User.count
    groups.count.must_equal Group.count
  end

  it 'should process :false filters' do
    filter = [:false]
    user_query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    group_query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    users = User.where(user_query)
    groups = Group.where(group_query)
    users.count.must_equal 0
    groups.count.must_equal 0
  end

  it 'should process :eq filters' do
    filter = [:eq, 'uid', nil, @john.name]
    query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    users = User.where(query)
    users.count.must_equal 1
    users.first.must_equal @john
  end

  it 'should process :or filters' do
    filter = [:or,
              [:eq, 'uid', nil, @john.name],
              [:eq, 'uid', nil, @jane.name]]
    query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    users = User.where(query).order(:id)
    users.count.must_equal 2
    users.all[0].must_equal @john
    users.all[1].must_equal @jane
  end

  it 'should process memberUid filters' do
    filter = [:eq, 'memberUid', nil, @jane.name]
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal 1
    groups.first.must_equal @all_group
  end

  it 'should process :and filters' do
    filter = [:and,
              [:eq, 'gidNumber', nil, @all_group.id],
              [:eq, 'memberUid', nil, @jane.name],
              [:not, [:eq, 'memberUid', nil, 'nonexistentusername42']]]
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal 1
    groups.first.must_equal @all_group
  end

  it 'should process :ge and :le filters' do
    filter = [:and,
              [:ge, 'gidNumber', nil, 65000],
              [:le, 'gidNumber', nil, 66000]]
    query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    users = User.where(query).order(:id)
    users.count.must_equal 2
    users.all[0].must_equal @john
    users.all[1].must_equal @jane
  end

  it 'should process :substrings filters' do
    filter = [:substrings, 'uid', nil, "jo", "doe"]
    query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    users = User.where(query)
    users.count.must_equal 1
    users.first.must_equal @john
  end

  it 'should process :substrings filters on memberUids' do
    filter = [:substrings, 'memberUid', nil, "jo", "doe"]
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal 1
    groups.first.must_equal @all_group
  end

  it 'should return no results for unknown attributes' do
    filter = [:eq, 'nonexistent', nil, 'somethingsomething']
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal 0
  end

  it 'should process objectClass :substrings requests' do
    # (objectClass=posixGr*)
    filter = [:substrings, 'objectClass', nil, 'posixGr', nil]
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal Group.count
  end

  it 'should process objectClass :eq requests' do
    # (objectClass=posixGroup)
    filter = [:eq, 'objectClass', nil, 'posixGroup']
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal Group.count
  end

  it 'should process objectClass :le requests' do
    # (objectClass<=posixGroupZZZ)
    filter = [:le, 'objectClass', nil, 'posixGroupZZZ']
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal Group.count
  end

  it 'should process objectClass :ge requests' do
    # (objectClass>=posixGroupGaaah)
    filter = [:ge, 'objectClass', nil, 'posixGaaah']
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups.count.must_equal Group.count
  end

  it 'should process :present filters' do
    # (homeDirectory=*)
    filter = [:present, 'homeDirectory']
    query = Ldumbd::FilterConverter.filter_to_sequel(User, filter)
    users = User.where(query)
    users.count.must_equal User.count
  end

  it 'should process :present filters on memberUids' do
    # (memberUid=*)
    filter = [:present, 'memberUid']
    query = Ldumbd::FilterConverter.filter_to_sequel(Group, filter)
    groups = Group.where(query)
    groups_with_members = Group.where(users: User.all)
    groups.count.must_equal groups_with_members.count
  end
end
