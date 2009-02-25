module EnumField
  def self.included(klass)
    klass.class_eval { extend EnumField::ClassMethods }
  end
  
  module ClassMethods
    # enum_field encapsulates a validates_inclusion_of and automatically gives you a 
    # few more goodies automatically.
    # 
    #     class Computer < ActiveRecord:Base
    #       enum_field :status, ['on', 'off', 'standby', 'sleep', 'out of this world']
    # 
    #       # Optionally with a message to replace the default one
    #       # enum_field :status, ['on', 'off', 'standby', 'sleep'], :message => "incorrect status"
    # 
    #       #...
    #     end
    # 
    # This will give you a few things:
    # 
    # - add a validates_inclusion_of with a simple error message ("invalid #{field}") or your custom message
    # - define the following query methods, in the name of expressive code:
    #   - on?
    #   - off?
    #   - standby?
    #   - sleep?
    #   - out_of_this_world?
    # - use :prefix => true to get the following query methods instead (useful on models with multiple enum_fields):
    #   - status_on?
    #   - status_off?
    #   - ...
    # - define the STATUSES constant, which contains the acceptable values
    def enum_field(field, possible_values, options={})
      message = options[:message] || "invalid #{field}"
      prefix = options[:prefix] ? "#{field}_" : ""
      const_set( field.to_s.pluralize.upcase, possible_values).freeze unless const_defined?(field.to_s.pluralize.upcase)
  
      possible_values.each do |current_value|
        suffix = current_value.downcase.gsub(/[-\s]/, '_')
        method_name = "#{prefix}#{suffix}"
        define_method("#{method_name}?") do
          self.send(field) == current_value
        end
      end
  
      validates_inclusion_of field, :in => possible_values, :message => message
    end
  end
end
