class Module
  def mattr_reader(*syms, instance_reader: true, instance_accessor: true)
    syms.each do |sym|
      raise NameError.new('invalid attribute name') unless sym =~ /^[_A-Za-z]\w*$/
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        @@#{sym} = nil unless defined? @@#{sym}

        def self.#{sym}
          @@#{sym}
        end
      EOS

      unless (instance_reader == false) || (instance_accessor == false)
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}
            @@#{sym}
          end
        EOS
      end
    end
  end

  def mattr_writer(*syms, instance_writer: true, instance_accessor: true)
    syms.each do |sym|
      raise NameError.new('invalid attribute name') unless sym =~ /^[_A-Za-z]\w*$/
      class_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
      EOS

      unless (instance_writer == false) || (instance_accessor == false)
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}=(obj)
            @@#{sym} = obj
          end
        EOS
      end
    end
  end

  # Extends the module object with module and instance accessors for class attributes,
  # just like the native attr* accessors for instance attributes.
  #
  #   module AppConfiguration
  #     mattr_accessor :google_api_key
  #
  #     self.google_api_key = "123456789"
  #   end
  #
  #   AppConfiguration.google_api_key # => "123456789"
  #   AppConfiguration.google_api_key = "overriding the api key!"
  #   AppConfiguration.google_api_key # => "overriding the api key!"
  #
  # To opt out of the instance writer method, pass <tt>instance_writer: false</tt>.
  # To opt out of the instance reader method, pass <tt>instance_reader: false</tt>.
  # To opt out of both instance methods, pass <tt>instance_accessor: false</tt>.
  def mattr_accessor(*syms, instance_reader: true, instance_writer: true, instance_accessor: true)
    mattr_reader(*syms, instance_reader: instance_reader, instance_accessor: instance_accessor)
    mattr_writer(*syms, instance_writer: instance_writer, instance_accessor: instance_accessor)
  end
end
