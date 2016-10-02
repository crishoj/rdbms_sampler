module RdbmsSampler

  class ForeignKey
    attr_reader :constraint_name
    attr_reader :schema
    attr_reader :table
    attr_reader :key
    attr_reader :referenced_schema
    attr_reader :referenced_table
    attr_reader :referenced_key

    def initialize(constraint_name, schema, table, key,
                   referenced_schema, referenced_table, referenced_key)

      @constraint_name = constraint_name
      @schema = schema
      @table = table
      @key = key
      @referenced_schema = referenced_schema
      @referenced_table = referenced_table
      @referenced_key = referenced_key
    end

  end

end