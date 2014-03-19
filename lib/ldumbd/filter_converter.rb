require 'ldumbd/table_map'

module Ldumbd
  class FilterConverter
    # Public: Converts a parsed LDAP filter to a Sequel dataset filter.
    #
    # base_model: The dataset's base model.
    # filter: A parsed LDAP filter.
    #
    # Examples
    #
    #   base_model = User
    #   filter = [:and,
    #              [:eq, 'uid', nil, 'john'],
    #              [:ge, 'uidNumber', nil, '1000']]
    #   base_model.where(Ldumbd::FilterConverter.filter_to_sequel(base_model,
    #                                                             filter)).sql
    #   # => "SELECT * FROM \"users\" WHERE ((\"users\".\"name\" = 'john') AND (\"users\".\"id\" >= '1000'))"
    #
    # Returns a Sequel dataset filter.
    def self.filter_to_sequel(base_model, filter)
      filter = filter.dup
      op = filter.shift
      case op
      when :and, :or, :not
        nested_filter_to_sequel(base_model, filter, op)
      when :true, :false, :eq, :ge, :le, :present, :substrings
        simple_filter_to_sequel(base_model, filter, op)
      else
        raise 'not implemented yet'
      end
    end

    private
    # Internal: Transforms a nested filter expression into a
    #           Sequel::SQL::BooleanExpression
    #
    # base_model: The dataset's base model.
    # filters: An array of parsed LDAP filters.
    # op: The type of nested filter, i.e. :or, :and or :not.
    #
    # Examples
    #
    #   base_model = User
    #   filters = [[:eq, 'uid', nil, 'john'],
    #              [:ge, 'uidNumber', nil, '1000']]
    #   op = :and
    #   query = Ldumbd::FilterConverter.nested_filter_to_sequel(base_model,
    #                                                           filters,
    #                                                           op)
    #   base_model.where(query).sql
    #   # => "SELECT * FROM \"users\" WHERE ((\"users\".\"name\" = 'john') AND (\"users\".\"id\" >= '1000'))"
    def self.nested_filter_to_sequel(base_model, filters, op)
      case op
      when :and
        Sequel.&(*filters.map { |f| filter_to_sequel(base_model, f) })
      when :or
        Sequel.|(*filters.map { |f| filter_to_sequel(base_model, f) })
      when :not
        raise ArgumentError, 'Too many :not arguments' unless filters.size == 1
        subfilter = filters[0]
        # ... id NOT IN (SELECT id FROM ...)
        Sequel.~(id: base_model.where(filter_to_sequel(base_model,
                                                       subfilter)).select(:id))
      end
    end

    # Internal: Transforms a non-nested filter expression into a sequel
    #           dataset filter.
    #
    # base_model: The dataset's base model.
    # filter: A parsed LDAP filter without a filter operator.
    # op: The filter type, e.g. :eq, :le, :ge, ...
    #
    # Examples
    #
    #   base_model = User
    #   filter = ['uid', nil, 'john']
    #   op = :eq
    #   query = Ldumbd::FilterConverter.simple_filter_to_sequel(base_model,
    #                                                           filter,
    #                                                           op)
    #   base_model.where(query).sql
    #   # => "SELECT * FROM \"users\" WHERE (\"users\".\"name\" = 'john')"
    def self.simple_filter_to_sequel(base_model, filter, op)
      key, value = extract_key_value(base_model, filter, op)
      return { key => value } if key == :users
      return oc_match?(base_model, op, value) if key == :object_class

      case op
      when :true
        true
      when :false
        false
      when :eq
        # TODO: no case insensitive search support yet
        #    User.where(Sequel.function(:lower, :name) => v.downcase)
        { key => value }
      when :le
        Sequel.expr(key) <= Sequel.expr(value)
      when :ge
        Sequel.expr(key) >= Sequel.expr(value)
      when :present
        !key.nil?
      when :substrings
        Sequel.like(key, value)
      end
    end

    # Internal: Extracts keys and values or Sequel filters for use in
    #           simple filters.
    #
    # model: The dataset's model.
    # filter: A parsed LDAP filter without a filter operator.
    # op: The filter type, e.g. :eq, :le, :ge, ...
    #
    # Examples
    #
    #   model = User
    #   filter = ['uid', nil, 'john']
    #   op = :eq
    #   Ldumbd::FilterConverter.extract_key_value(model, filter, op)
    #   # => [:users__name, "john"]
    def self.extract_key_value(model, filter, op)
      ldap_value = filter[2..-1] || []
      key = extract_key(model, filter)

      value = if key == :users
                User.where(filter_to_sequel(User, [op, 'uid', nil, ldap_value]))
              elsif op == :substrings
                ldap_value.join('%')
              else
                ldap_value[0]
              end

      return key, value
    end

    # Internal: Extracts LDAP keys from parsed LDAP filters and
    #           converts them to SQL attributes.
    #
    # model: The dataset model.
    # filter: A parsed LDAP filter without a filter operator.
    #
    # Examples
    #
    #   model = User
    #   filter = ['uid', nil, 'john']
    #   Ldumbd::FilterConverter.extract_key(model, filter)
    #   # => :users__name
    def self.extract_key(model, filter)
      ldap_key = filter[0]
      if ldap_key == 'objectClass'
        # object classes are not saved in the database
        :object_class
      else
        TableMap.db_key(model, ldap_key)
      end
    end

    # Internal: Checks whether a model matches a target object class.
    #
    # model: The model.
    # op: An LDAP filter operator, i.e. :eq, :le, :ge or :substrings.
    # target_oc: The target object class.
    #
    # Examples
    #
    #   Ldumbd::FilterConverter.oc_match?(User, :ge, 'posixA')
    #   # => true
    #
    #   Ldumbd::FilterConverter.oc_match?(Group, :eq, 'nonexistent')
    #   # => false
    def self.oc_match?(model, op, target_oc)
      object_classes = TableMap.object_classes(model)

      case op
      when :eq
        object_classes.any? { |oc| oc == target_oc }
      when :le
        object_classes.any? { |oc| oc <= target_oc }
      when :ge
        object_classes.any? { |oc| oc >= target_oc }
      when :substrings
        target_oc_re = /\A#{Regexp.escape(target_oc).gsub('%', '.*')}\Z/
        object_classes.any? { |oc| oc =~ target_oc_re }
      end
    end
  end
end
