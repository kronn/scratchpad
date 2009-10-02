module DisableForeignKeys
  class << self
    # Disable Keys or constraints during extensive database Operations
    #
    # FIXME This is MySQL-specific, therefore horrible
    def without_constraints
      return unless block_given?

      # disable constraints and indices
      connection.execute("SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;")
      connection.execute("ALTER TABLE #{table_name} DISABLE KEYS;")

      result = yield connection

      # reenabale constraints and indices
      connection.execute("ALTER TABLE #{table_name} ENABLE KEYS;")
      connection.execute("SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;")

      result
    end

    def execute_without_constraints query
      without_constraints do |conn|
        conn.execute query
      end
    end
  end
end

module ActiveRecord
  class Base
    include DisableForeignKeys
  end
end
