require "data_sampler/dependency"

module DataSampler

  class TableSample

    attr_reader :table_name
    attr_reader :pending_dependencies

    def initialize(connection, table_name, size = 1000)
      @table_name = table_name
      @connection = connection
      @size = size
      @pending_dependencies = Set.new
      @sample = Set.new
      @sampled = false
      @sampled_ids = Set.new
    end

    def sample!
      fetch_sample(@size) unless @sampled
      @sample
    end

    def fulfil(dependency)
      return if fulfilled?(dependency)
      where = dependency.keys.collect { |col, val| "#{@connection.quote_column_name col} = #{@connection.quote val}" } * ' AND '
      sql = "SELECT * FROM #{@connection.quote_table_name @table_name} WHERE " + where
      add @connection.select_one(sql)
    end

    def fulfilled?(dependency)
      # FIXME: Only checks id column
      if dependency.keys.values.size == 1
        dependency.keys.each_pair do |key, val|
          if key == 'id'
            return true if @sampled_ids.include?(val)
          end
        end
      end
      false
    end

    def add(row)
      return false unless @sample.add? row
      @sampled_ids.add row['id'] if row['id']
      any_new = false
      dependencies_for(row).each do |dep|
        any_new = true if @pending_dependencies.add?(dep)
      end
      any_new
    rescue ActiveRecord::StatementInvalid => e
      # Don't choke on unknown table engines, such as Sphinx
    end

    def ensure_referential_integrity(table_samples)
      any_new = false
      deps_in_progress = @pending_dependencies
      @pending_dependencies = Set.new
      deps_in_progress.each do |dependency|
        raise "Table sample for #{dependency.table_name} not found" unless table_samples[dependency.table_name]
        any_new = true if table_samples[dependency.table_name].fulfil(dependency)
      end
      any_new
    end

    def to_sql
      ret = ["-- #{@table_name}: #{@sample.count} rows"]
      unless @sample.empty?
        quoted_cols = @sample.first.keys.collect { |col| @connection.quote_column_name col }
        sql = "INSERT INTO #{@connection.quote_table_name @table_name} (#{quoted_cols * ','})"
        @sample.each do |row|
          quoted_vals = []
          row.each_pair do |field,val|
            val.gsub! /./, '*' if field.downcase == 'password'
            quoted_vals << @connection.quote(val)
          end
          ret << sql + " VALUES (#{quoted_vals * ','});"
        end
      end
      ret * "\n"
    end

    protected

    def fetch_sample(count)
      warn "  Sampling #{count} rows from table `#{@table_name}`"
      sql = "SELECT * FROM #{@connection.quote_table_name @table_name}"
      pk = @connection.primary_key(@table_name)
      sql += " ORDER BY #{@connection.quote_column_name pk} DESC" unless pk.nil?
      sql += " LIMIT #{count}"
      @connection.select_all(sql).each { |row| add(row) }
    rescue ActiveRecord::StatementInvalid => e
      # Don't choke on unknown table engines, such as Sphinx
      []
    end

    def samplable?
      # We shouldn't be sampling views
      @connection.views.grep(@table_name).empty?
    end

    def dependency_for(fk, row)
      ref = {}
      cols = fk.column_names.dup
      raise "No column names in foreign key #{fk.inspect}" if cols.empty?
      fk.references_column_names.each do |ref_col|
        col = cols.shift
        ref[ref_col] = row[col] unless row[col].nil?
      end
      Dependency.new(fk.references_table_name, ref) unless ref.empty?
    end

    def dependencies_for(row)
      foreign_keys.collect { |fk| dependency_for(fk, row) }.compact
    end

    def foreign_keys
      @fks ||= @connection.foreign_keys(@table_name)
    end

  end
end
