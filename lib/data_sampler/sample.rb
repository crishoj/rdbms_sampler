require "data_sampler/table_sample"

module DataSampler

  class Sample

    def initialize(connection, rows_per_table = 1000)
      @connection = connection
      @rows_per_table = rows_per_table
      @table_samples = {}
      @computed = false
    end

    def compute!
      @connection.tables.each do |table_name|
        # Workaround for inconsistent casing in table definitions (http://bugs.mysql.com/bug.php?id=60773)
        table_name.downcase!
        @table_samples[table_name] = TableSample.new(@connection, table_name, @rows_per_table)
      end
      warn "Sampling #{@table_samples.count} tables..."
      @table_samples.values.map &:sample!
      warn "Ensuring referential integrity..."
      begin
        new_dependencies = 0
        @table_samples.values.each do |table_sample|
          new_dependencies += 1 if table_sample.ensure_referential_integrity(@table_samples)
        end
        warn " - discovered #{new_dependencies} new dependencies" if new_dependencies > 0
      end while new_dependencies > 0
      warn " - referential integrity obtained"
      @computed = true
    end

    def to_sql
      compute! unless @computed
      @table_samples.values.collect(&:to_sql) * "\n"
    end

  end

end