module RdbmsSampler
  class Dependency

    attr_reader :parent_schema
    attr_reader :parent_table
    attr_reader :parent_key
    attr_reader :child_schema_name
    attr_reader :child_table_name
    attr_reader :child_key
    attr_reader :value

    def initialize(parent_schema, parent_table, parent_key, child_schema, child_table, child_key, value)
      @parent_schema = parent_schema
      @parent_table = parent_table
      @parent_key = parent_key
      @child_schema_name = child_schema
      @child_table_name = child_table
      @child_key = child_key
      @value = value
    end

    def identifier
      "#{child_schema_name}.#{child_table_name}"
    end

    def eql? other
      identifier == other.identifier and child_key == other.child_key and value == other.value
    end

    def to_s
      "reference from #{parent_schema}.#{parent_table}.#{parent_key} to #{identifier}[#{child_key}=#{value}]"
    end

  end
end