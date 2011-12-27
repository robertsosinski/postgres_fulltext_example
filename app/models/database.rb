class Database < ActiveRecord::Base
  set_table_name false

  def after_initialize
    readonly!
  end

  class << self
    [:select_all, :select_one, :select_rows, :select_value, :select_values, :update, :delete].each do |method|
      eval <<-CODE
        def #{method}(sql, name = nil)
          connection.#{method}(sanitize_sql(sql, false))
        end
      CODE
    end

    def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
      connection.insert(sanitize_sql(sql), name, pk, id_value, sequence_name)
    end

    def execute(sql, name = nil, skip_logging = false)
      connection.execute(sanitize_sql(sql), name, skip_logging)
    end
  end
end
