require 'ldap/server'
require 'sequel'
require 'ldumbd/filter_converter'

module Ldumbd
  class TreeObject
    attr_accessor :children
    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes
      @children = []
    end

    def matches_filter?(filter)
      ldap_object = TableMap.sequel_to_ldap_object(@attributes)
      LDAP::Server::Filter.run(filter, ldap_object)
    end

    def each_child(filter = [:true], recurse = false, &block)
      @children.each do |child|
        if child.is_a?(TreeObject)
          if LDAP::Server::Filter.run(filter, child.attributes)
            yield child.attributes
          end
          child.each_child(filter, recurse, &block) if recurse
        elsif child < Sequel::Model
          query = Ldumbd::FilterConverter.filter_to_sequel(child, filter)
          child.where(query).each do |r|
            yield r
          end
        end
      end
    end

    def self.by_dn(basedn, dn)
      object = nil

      dn_filter, model = dn_to_filter_and_model(basedn, dn)
      if dn_filter
        query = Ldumbd::FilterConverter.filter_to_sequel(model, dn_filter)
        result = model.where(query).first
        object = result ? self.new(result) : nil
      end
      object
    end

    def self.attribute_from_dn(basedn, dn, attribute, ou)
      dn.scan(/\A#{attribute}=([^,]*),ou=#{ou},#{basedn}\z/).flatten.last
    end
    private_class_method :attribute_from_dn

    def self.dn_to_filter_and_model(basedn, dn)
      uid = attribute_from_dn(basedn, dn, 'uid', 'People')
      cn = attribute_from_dn(basedn, dn, 'cn', 'Groups')

      if uid
        return [:eq, 'uid', nil, uid], User
      elsif cn
        return [:eq, 'cn', nil, cn], Group
      else
        return nil, nil
      end
    end
    private_class_method :dn_to_filter_and_model
  end
end
