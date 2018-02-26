require 'rdbms_sampler/table_sample'
require 'active_support/core_ext/array'

module RdbmsSampler

  class Sample

    def initialize(options ={})
      @connection = options[:conn]
      @rows_per_table = options[:rows_per_table] || 1000
      @table_samples = {}
      @schemas = options[:schemas]
      @computed = false
      @connection.execute 'SET SESSION TRANSACTION READ ONLY, ISOLATION LEVEL REPEATABLE READ'
      @connection.execute 'START TRANSACTION'
    end

    def compute!
      quoted_schema_names = @schemas.collect do |name|
        @connection.quote_table_name(name)
      end
      warn "Discovering tables in databases: #{quoted_schema_names.to_sentence}..."
      tables_without_views.each do |schema_name, table_name|
        table_sample = TableSample.new(@connection, schema_name, table_name, @rows_per_table)
        @table_samples[table_sample.identifier] = table_sample
      end
      return warn 'No tables found!' unless @table_samples.count > 0
      warn "Sampling #{@table_samples.count} tables..."
      @table_samples.values.map &:sample!
      warn 'Ensuring referential integrity...'
      begin
        new_dependencies = 0
        @table_samples.values.each do |table_sample|
          newly_added = table_sample.ensure_referential_integrity(self)
          if newly_added > 0
            new_dependencies += newly_added
            warn "  Expanded sample with #{newly_added} new rows referenced from table #{table_sample.quoted_name}"
          end
        end
        warn " Discovered #{new_dependencies} new dependencies" if new_dependencies > 0
      end while new_dependencies > 0
      warn 'Referential integrity obtained'

      warn 'Final sample contains:'
      @table_samples.values.each do |table_sample|
        warn "  #{table_sample.size} row(s) from `#{table_sample.identifier}`"
      end
      @computed = true
    end

    # @param [Dependency]
    # @return [TableSample]
    def table_sample_for_dependency(dependency)
      raise "Table sample for [#{dependency.identifier}] not found" unless @table_samples.include? dependency.identifier
      @table_samples[dependency.identifier]
    end

    def to_sql
      compute! unless @computed
      @table_samples.values.collect(&:to_sql) * "\n"
    end

    private

    def tables_without_views
      quoted_schema_names = @schemas.collect { |name|
        @connection.quote(name)
      }.join(', ')
      @connection.execute <<SQL
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
          AND TABLE_SCHEMA IN (#{quoted_schema_names})
SQL
    end
  end

end
