module DataSampler
  class Dependency

    attr_reader :table_name
    attr_reader :keys
    attr_reader :referring_table_name

    def initialize(table_name, keys, referring_table_name)
      @table_name = table_name
      @keys = keys
      @referring_table_name = referring_table_name
    end

    def eql? other
      table_name == other.table_name and keys == other.keys
    end

    def to_s
      "row with keys #{keys} in table `#{table_name}` (referred from `#{referring_table_name}`)"
    end

  end
end