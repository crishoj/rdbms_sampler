module DataSampler
  class Dependency

    attr_reader :table_name
    attr_reader :keys

    def initialize(table_name, keys)
      @table_name = table_name
      @keys = keys
    end

    def eql? other
      table_name == other.table_name and keys == other.keys
    end

    def to_s
      "#{keys} in table #{table_name}"
    end

  end
end