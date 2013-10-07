require_relative './db_connection'

module Searchable
  def where(params)
    columns = params.keys
    values = params.values
    where_string = columns.map { |col| "#{col} = ?" }.join(" AND ")
    parse_all(DBConnection.execute(<<-SQL, *values))
      SELECT *
      FROM #{table_name}
      WHERE #{where_string}
    SQL
  end
end