module Ldumbd
  class TableMap
    TABLE_MAP = {
      group: {
        object_classes: ['posixGroup'],
        attributes: {
          'gidNumber' => :groups__id,
          'cn'        => :groups__name,
          'memberUid' => :users
        },
      },
      user: {
        object_classes: ['posixAccount'],
        attributes: {
          'uidNumber'     => :users__id,
          'uid'           => :users__name,
          'cn'            => :users__realname,
          'loginShell'    => :users__shell,
          'homeDirectory' => :users__homedir,
          'gidNumber'     => :users__group_id
        }
      }
    }

    def self.invert_attribute_map(attributes)
      attribute_array = attributes.map do |ldap_key, db_key|
        /\A[a-z]*__(?<db_key_compact>.*)\z/ =~ db_key.to_s
        [db_key_compact.nil? ? nil : db_key_compact.to_sym, ldap_key]
      end
      Hash[attribute_array].delete_if { |k, v| k.nil? }
    end
    private_class_method :invert_attribute_map

    def self.invert_table_map(table_map)
      table_array = table_map.map do |model, properties|
        [model, invert_attribute_map(properties[:attributes])]
      end
      Hash[table_array]
    end
    private_class_method :invert_table_map

    INVERSE_TABLE_MAP = invert_table_map(TABLE_MAP)

    def self.db_key(model, ldap_key)
      table = model_to_sym(model)
      TABLE_MAP[table][:attributes][ldap_key]
    end

    def self.object_classes(model)
      table = model_to_sym(model)
      TABLE_MAP[table][:object_classes]
    end

    def self.model_to_sym(model)
      model.name.downcase.to_sym
    end
    private_class_method :model_to_sym

    def self.ldap_keys(model)
      table = model_to_sym(model)
      INVERSE_TABLE_MAP[table]
    end

    def self.sequel_to_ldap_object(sequel_object)
      # return unmodified object if it is not a Sequel model instance
      return sequel_object unless sequel_object.is_a?(Sequel::Model)

      model = sequel_object.class
      ldap_keys = ldap_keys(model)
      ldap_array = sequel_object.values.map do |sequel_key, value|
        # LDAP::Server expects all values to be Arrays
        [ldap_keys[sequel_key], [value]]
      end
      ldap_object = Hash[ldap_array]

      ldap_object['objectClass'] = object_classes(model)
      if sequel_object.is_a?(Group)
        ldap_object['dn_prefix'] = "cn=#{sequel_object.name},ou=Groups"
        if sequel_object.users.any?
          ldap_object['memberUid'] = sequel_object.users.map { |u| u.name }
        end
      elsif sequel_object.is_a?(User)
        ldap_object['dn_prefix'] = "uid=#{sequel_object.name},ou=People"
      end
      ldap_object
    end
  end
end
