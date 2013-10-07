require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable, Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.class.to_s.underscore.pluralize
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL))
      SELECT *
      FROM #{table_name}
    SQL
  end

  def self.find(id)
    new(DBConnection.execute(<<-SQL, id).first)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
  end

  def save
    id.nil? ? create : update
  end

  private
  def create
    attributes = self.class.attributes
    table_name = self.class.table_name
    column_names = attributes.map { |attr| attr.to_s }.join(", ")
    value_placeholders = (["?"] * attributes.size).join(", ")
    values = attribute_values
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO #{table_name}(#{column_names})
      VALUES (#{value_placeholders})
    SQL
    @id = DBConnection.last_insert_row_id
  end

  def update
    attributes = self.class.attributes
    table_name = self.class.table_name
    set_string = attributes.map { |attr| "#{attr} = ?" }.join(", ")
    values = attribute_values
    DBConnection.execute(<<-SQL, *values, id)
      UPDATE #{table_name}
      SET #{set_string}
      WHERE id = ?
    SQL
    @id
  end

  def attribute_values
    self.class.attributes.map { |prop| send(prop) }
  end
end
