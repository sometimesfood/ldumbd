require 'ldap/server'

module Ldumbd
  class Operation < LDAP::Server::Operation
    def initialize(connection, messageID, ldap_tree)
      super(connection, messageID)
      @ldap_tree = ldap_tree
    end

    def search_results(basedn, scope, deref, filter)
      case scope
      when LDAP::Server::BaseObject
        # the base object only
        object = @ldap_tree.find_by_dn(basedn)
        if object.matches_filter?(filter) && block_given?
          yield TableMap.sequel_to_ldap_object(object.attributes)
        end

      when LDAP::Server::SingleLevel
        # objects immediately subordinate to the base object; does not
        # include the base object itself.
        object = @ldap_tree.find_by_dn(basedn)
        object.each_child(filter) do |r|
          yield TableMap.sequel_to_ldap_object(r) if block_given?
        end

      when LDAP::Server::WholeSubtree
        # base object and the entire subtree, also includes the base
        # object itself.
        object = @ldap_tree.find_by_dn(basedn)
        if object.matches_filter?(filter) && block_given?
          yield TableMap.sequel_to_ldap_object(object.attributes)
        end
        object.each_child(filter, true) do |r|
          yield TableMap.sequel_to_ldap_object(r) if block_given?
        end
      else
        raise LDAP::ResultError::UnwillingToPerform, 'Invalid search scope'
      end
    end

    def stringify(hash)
      Hash[hash.map { |k, v| [k.to_s, v.to_s] } ]
    end

    def search(basedn, scope, deref, filter)
      search_results(basedn, scope, deref, filter) do |ldap_object|
        # TODO: build a proper DN here
        dn = @ldap_tree.dn(ldap_object['dn_prefix'])
        object = ldap_object.reject { |k, v| k == 'dn_prefix' }
        send_SearchResultEntry(dn, object)
      end
    end
  end # Operation
end # Ldumbd
