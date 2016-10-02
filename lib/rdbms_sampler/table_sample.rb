require 'pry'
require 'rdbms_sampler/dependency'
require 'rdbms_sampler/foreign_key'

module RdbmsSampler

  class TableSample

    attr_reader :pending_dependencies

    def initialize(connection, schema_name, table_name, size = 1000)
      @schema = schema_name
      @table = table_name
      @connection = connection
      @size = size
      @pending_dependencies = Set.new
      @sample = Set.new
      @sampled = false
      @sampled_ids = Set.new
    end

    def sample!
      fetch(@size) unless @sampled
      @sample
    end

    def size
      @sampled ? @sample.size : @size
    end

    def identifier
      "#{@schema}.#{@table}"
    end

    # Add the given dependency to the sample
    # @param [Dependency] dependency
    def fulfil(dependency)
      return 0 if fulfilled?(dependency)
      quoted_column = @connection.quote_column_name dependency.child_key
      quoted_value = @connection.quote dependency.value
      sql = "SELECT * FROM #{quoted_name} WHERE #{quoted_column} = #{quoted_value}"
      row = @connection.select_one(sql)
      raise "Could not fulfil #{dependency} using query [#{sql}]" if row.nil?
      add row
    end

    # @param [Dependency] dependency
    def fulfilled?(dependency)
      # FIXME: Only handles `id` column
      return false if dependency.child_key != 'id'

      @sampled_ids.include?(dependency.value)
    end

    # Add a row to the table sample.
    # Returns number of new dependencies introduced.
    def add(row)
      return 0 unless @sample.add? row
      @sampled_ids.add row['id'] if row['id']
      dependencies_for(row).collect { |dep|
        1 if @pending_dependencies.add?(dep)
      }.compact.sum
    end

    # @param [Sample] sample
    def ensure_referential_integrity(sample)
      dependencies_in_progress = @pending_dependencies
      @pending_dependencies = Set.new
      dependencies_in_progress.map { |dependency|
        dependency_sample = sample.table_sample_for_dependency(dependency)
        dependency_sample.fulfil(dependency)
      }.compact.sum
    end

    def to_sql
      ret = "\n-- Sample from #{quoted_name} (#{@sample.count} rows)\n"
      unless @sample.empty?
        quoted_cols = @sample.first.keys.collect { |col| @connection.quote_column_name col }
        # INSERT in batches to reduce the likelihood of hitting `max_allowed_packet`
        @sample.each_slice(250) do |rows|
          values = rows.collect { |row|
            row.values.map { |val|
              @connection.quote(val)
            } * ','
          } * "),\n  ("
          ret << "INSERT INTO #{quoted_name} \n  (#{quoted_cols * ','}) \nVALUES \n  (#{values});\n"
        end
      end
      ret
    end

    def quoted_name
      @connection.quote_table_name(@schema)+'.'+@connection.quote_table_name(@table)
    end

    protected

    def fetch(count = 1000)
      warn "  Sampling #{count} rows from #{quoted_name}..."
      sql = "SELECT * FROM #{quoted_name}"
      pk = @connection.primary_key(@table)
      sql += " ORDER BY #{@connection.quote_column_name pk} DESC" unless pk.nil?
      sql += " LIMIT #{count}"
      @connection.select_all(sql).each { |row| add(row) }
      @sampled = true
    end

    # @param [ForeignKey] fk
    # @param [Array] row
    def dependency_for(fk, row)
      unless (value = row[fk.key]).nil?
        Dependency.new(fk.schema, fk.table, fk.key, fk.referenced_schema, fk.referenced_table, fk.referenced_key, value)
      end
    end

    # @param [Array] row
    def dependencies_for(row)
      foreign_keys.collect { |fk| dependency_for(fk, row) }.compact
    end

    def foreign_keys
      @fks ||= discover_foreign_keys
    end

    def discover_foreign_keys
      quoted_schema = @connection.quote @schema
      quoted_table = @connection.quote @table

      sql = <<SQL
      SELECT
        fk.constraint_name,
        fk.table_schema,
        fk.table_name,
        fk.column_name,
        fk.referenced_table_schema,
        fk.referenced_table_name,
        fk.referenced_column_name
      FROM information_schema.key_column_usage fk
      WHERE fk.referenced_column_name IS NOT NULL
      AND fk.table_schema = #{quoted_schema}
      AND fk.table_name = #{quoted_table}
SQL

      @connection.execute(sql).map do |row|
        ForeignKey.new(*row)
      end
    end

  end
end
