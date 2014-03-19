require 'ldumbd/tree_object'

module Ldumbd
  class LdapTree
    def find_by_dn(dn)
      object = @tree[dn]
      unless object
        object = TreeObject.by_dn(@basedn, dn)
      end
      object or raise LDAP::ResultError::NoSuchObject
    end

    def initialize(basedn)
      @basedn = basedn
      /\Adc=(?<dc>[^,]*)/ =~ basedn
      root = TreeObject.new({ 'dn_prefix' => '',
                              'dc' => dc,
                              'objectClass' => ['top', 'domain']})
      people = TreeObject.new({ 'dn_prefix' => 'ou=People',
                                'ou' => 'People',
                                'objectClass' => ['top',
                                                  'organizationalUnit'] })
      groups = TreeObject.new({ 'dn_prefix' => 'ou=Groups',
                                'ou' => 'Groups',
                                'objectClass' => ['top',
                                                  'organizationalUnit'] })
      root.children << people
      root.children << groups
      people.children << User
      groups.children << Group

      @tree = Hash[
                   [root, people, groups].map do |object|
                     dn_prefix = object.attributes['dn_prefix']
                     [dn(dn_prefix), object]
                   end
                  ]
    end

    def dn(dn_prefix)
      [dn_prefix, @basedn].reject(&:empty?).join(',')
    end
  end
end
