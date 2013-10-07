class MassObject
  def self.my_attr_accessible(*attributes)
    @attributes = attributes
    attributes.each { |attr| attr_accessor(attr) }
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map { |result| new(result) }
  end

  def initialize(params = {})
    params.each do |attr, val|
      if self.class.attributes.include?(attr.to_sym)
        send(attr.to_s + "=", val)
      else
        p self.class.attributes
        raise "mass assignment to unregistered attribute #{attr}"
      end
    end
  end
end