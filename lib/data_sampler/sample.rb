require "data_sampler/table_sample"

module DataSampler

  class Sample

    #def initialize(connection, rows_per_table = 1000, database = 'test')
    def initialize(options ={})
      @connection = options[:conn]
      @rows_per_table = options[:rows_per_table] || 1000
      @table_samples = {}
      @schema = options[:schema]
      @computed = false
    end

    def compute!

      tables_without_views(@schema).each  do |table_name|
        table_name = table_name.first
        # Workaround for inconsistent casing in table definitions (http://bugs.mysql.com/bug.php?id=60773)
        # table_name.downcase!
        ##unless TABLE_TYPE == VIEW
        @table_samples[table_name] = TableSample.new(@connection, table_name, @rows_per_table)
      end
      warn "Sampling #{@table_samples.count} tables from database `#{@connection.current_database}`..."
      @table_samples.values.map &:sample!
      warn "Ensuring referential integrity..."
      begin
        new_dependencies = 0
        @table_samples.values.each do |table_sample|
          newly_added = table_sample.ensure_referential_integrity(@table_samples)
          if newly_added > 0
            new_dependencies += newly_added
            warn "  Found #{newly_added} new dependents for table `#{table_sample.table_name}`"
          end
        end
        warn " Discovered #{new_dependencies} new dependencies" if new_dependencies > 0
      end while new_dependencies > 0
      warn "Referential integrity obtained"

      warn "Final sample contains:"
      @table_samples.values.each do |table_sample|
        warn "  #{table_sample.size} row(s) from `#{table_sample.table_name}`"
      end
      @computed = true
    end

    def to_sql
      compute! unless @computed
      @table_samples.values.collect(&:to_sql) * "\n"
    end

    private

    # fetch table_names from db without views
    def tables_without_views(table_schema )
      sql =  "SELECT TABLE_NAME  FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = '#{table_schema}'"
      execute_statement(sql)
    end

    # filter out error message
    def execute_statement(sql)
      results = @connection.execute(sql)
      if results.present?
        return results
      else
        warn "No tables found, please check schema name and DB content"
        return nil
      end
    end

  end

end
