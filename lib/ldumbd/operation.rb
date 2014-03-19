require 'ldap/server'

module Ldumbd
  class Operation < LDAP::Server::Operation
    def initialize(connection, messageID, ldap_tree)
      super(connection, messageID)
      @ldap_tree = ldap_tree
    end

    def search(basedn, scope, deref, filter)
      search_results(basedn, scope, deref, filter) do |ldap_object|
        dn = @ldap_tree.dn(ldap_object['dn_prefix'])
        object = ldap_object.reject { |k, v| k == 'dn_prefix' }
        send_SearchResultEntry(dn, object)
      end
    end

    private
    def search_results(basedn, scope, deref, filter, &block)
      case scope
      when LDAP::Server::BaseObject
        search_results_baseobject(basedn, filter, &block)
      when LDAP::Server::SingleLevel
        search_results_singlelevel(basedn, filter, &block)
      when LDAP::Server::WholeSubtree
        search_results_subtree(basedn, filter, &block)
      else
        raise LDAP::ResultError::UnwillingToPerform, 'Invalid search scope'
      end
    end

    def search_results_baseobject(basedn, filter, &block)
      # the base object only
      object = @ldap_tree.find_by_dn(basedn)
      if object.matches_filter?(filter) && block_given?
        block.call(TableMap.sequel_to_ldap_object(object.attributes))
      end
    end

    def search_results_singlelevel(basedn, filter, &block)
      # objects immediately subordinate to the base object; does not
      # include the base object itself.
      object = @ldap_tree.find_by_dn(basedn)
      object.each_child(filter) do |r|
        block.call(TableMap.sequel_to_ldap_object(r)) if block_given?
      end
    end

    def search_results_subtree(basedn, filter, &block)
      # base object and the entire subtree, also includes the base
      # object itself.
      object = @ldap_tree.find_by_dn(basedn)
      if object.matches_filter?(filter) && block_given?
        block.call(TableMap.sequel_to_ldap_object(object.attributes))
      end
      object.each_child(filter, true) do |r|
        block.call(TableMap.sequel_to_ldap_object(r)) if block_given?
      end
    end
  end # Operation
end # Ldumbd
