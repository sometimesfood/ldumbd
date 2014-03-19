require_relative 'spec_helper'

require 'ldumbd/table_map'

describe Ldumbd::TableMap do
  before(:each) do
    @john = new_user('John Doe')
    @jane = new_user('Jane Doe')
    @all_group = Group.create(name: 'allusers')
    @all_group.add_user(@john)
    @all_group.add_user(@jane)
  end

  describe 'sequel_to_ldap_object' do
    it 'should return Hash objects unmodified' do
      foobarbaz = {foo: [:bar, :baz]}
      Ldumbd::TableMap.sequel_to_ldap_object(foobarbaz).must_equal foobarbaz
    end

    it 'should convert User objects' do
      expected = {
        'uidNumber'     => [@john.id],
        'uid'           => [@john.name],
        'cn'            => [@john.realname],
        'loginShell'    => [@john.shell],
        'homeDirectory' => [@john.homedir],
        'gidNumber'     => [@john.group_id],
        'objectClass'   => ['posixAccount'],
        'dn_prefix'     => "uid=#{@john.name},ou=People"
      }
      Ldumbd::TableMap.sequel_to_ldap_object(@john).must_equal expected
    end

    it 'should convert Group objects' do
      expected = {
        'gidNumber'     => [@all_group.id],
        'cn'            => [@all_group.name],
        'memberUid'     => [@john.name, @jane.name],
        'objectClass'   => ['posixGroup'],
        'dn_prefix'     => "cn=#{@all_group.name},ou=Groups"
      }
      Ldumbd::TableMap.sequel_to_ldap_object(@all_group).must_equal expected
    end
  end
end
