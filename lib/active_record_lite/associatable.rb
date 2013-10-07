require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :foreign_key, :primary_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelcase
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
    @primary_key = params[:primary_key] || :id
  end

  def type
    :belongs_to
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @foreign_key = params[:foreign_key] || "#{self_class.to_s.underscore}_id".to_sym
    @primary_key = params[:primary_key] || :id
  end

  def type
    :has_many
  end
end

module Associatable
  def assoc_params
    @@assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    params = BelongsToAssocParams.new(name, params)
    assoc_params[name] = params
    define_method(name) do
      params.other_class.new(DBConnection.execute(<<-SQL, send(params.foreign_key)).first)
        SELECT *
        FROM #{params.other_table}
        WHERE #{params.primary_key} = ?
      SQL
    end
  end

  def has_many(name, params = {})
    params = HasManyAssocParams.new(name, params, self.class)
    assoc_params[name] = params
    define_method(name) do
      params.other_class.parse_all(DBConnection.execute(<<-SQL, send(params.primary_key)))
        SELECT *
        FROM #{params.other_table}
        WHERE #{params.foreign_key} = ?
      SQL
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params = self.class.assoc_params[assoc1]
      through_params = self.class.assoc_params[assoc2]

      join_table = params.other_table
      result_table = through_params.other_table

      join_foreign_key = params.foreign_key
      join_primary_key = params.primary_key
      result_foreign_key = through_params.foreign_key
      result_primary_key = through_params.primary_key

      through_params.other_class.new(DBConnection.execute(<<-SQL, send(join_foreign_key)).first)
        SELECT #{result_table}.*
        FROM #{join_table}
        JOIN #{result_table}
        ON #{join_table}.#{result_foreign_key} = #{result_table}.#{result_primary_key}
        WHERE #{join_table}.#{join_primary_key} = ?
      SQL
    end
  end
end
