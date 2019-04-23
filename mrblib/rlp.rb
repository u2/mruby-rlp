module RLP

  module Constant
    SHORT_LENGTH_LIMIT = 56
    LONG_LENGTH_LIMIT = 256**8

    PRIMITIVE_PREFIX_OFFSET = 0x80
    LIST_PREFIX_OFFSET = 0xc0

    BYTE_ZERO = "\x00".freeze
    BYTE_EMPTY = ''.freeze
  end

  class Data < String
  end

  class TypeError < StandardError; end

  module Error
    class RLPException < StandardError; end

    class EncodingError < RLPException
      attr :obj

      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class DecodingError < RLPException
      attr :rlp

      def initialize(message, rlp)
        super(message)

        @rlp = rlp
      end
    end

    class SerializationError < RLPException
      attr :obj

      def initialize(message, obj)
        super(message)

        @obj = obj
      end
    end

    class DeserializationError < RLPException
      attr :serial

      def initialize(message, serial)
        super(message)

        @serial = serial
      end
    end

    class ListSerializationError < SerializationError
      attr :index, :element_exception

      def initialize(message = nil, obj = nil, element_exception = nil, index = nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Serialization failed because of element at index #{index} ('#{element_exception}')"
        end

        super(message, obj)

        @index = index
        @element_exception = element_exception
      end
    end

    class ListDeserializationError < DeserializationError
      attr :index, :element_exception

      def initialize(message = nil, serial = nil, element_exception = nil, index = nil)
        if message.nil?
          raise ArgumentError, "index and element_exception must be present" if index.nil? || element_exception.nil?
          message = "Deserialization failed because of element at index #{index} ('#{element_exception}')"
        end

        super(message, serial)

        @index = index
        @element_exception = element_exception
      end
    end

    ##
    # Exception raised if serialization of a {RLP::Sedes::Serializable} object
    # fails.
    #
    class ObjectSerializationError < SerializationError
      attr :field, :list_exception

      ##
      # @param sedes [RLP::Sedes::Serializable] the sedes that failed
      # @param list_exception [RLP::Error::ListSerializationError] exception raised by the underlying
      #   list sedes, or `nil` if no exception has been raised
      #
      def initialize(message = nil, obj = nil, sedes = nil, list_exception = nil)
        if message.nil?
          raise ArgumentError, "list_exception and sedes must be present" if list_exception.nil? || sedes.nil?

          if list_exception.element_exception
            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Serialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Serialization failed because of underlying list ('#{list_exception}')"
          end
        else
          field = nil
        end

        super(message, obj)

        @field = field
        @list_exception = list_exception
      end
    end

    ##
    # Exception raised if deserialization by a {RLP::Sedes::Serializable} fails.
    #
    class ObjectDeserializationError < DeserializationError
      attr :sedes, :field, :list_exception

      ##
      # @param sedes [RLP::Sedes::Serializable] the sedes that failed
      # @param list_exception [RLP::ListDeserializationError] exception raised
      #   by the underlying list sedes, or `nil` if no such exception has been
      #   raised
      #
      def initialize(message = nil, serial = nil, sedes = nil, list_exception = nil)
        if message.nil?
          raise ArgumentError, "list_exception must be present" if list_exception.nil?

          if list_exception.element_exception
            raise ArgumentError, "sedes must be present" if sedes.nil?

            field = sedes.serializable_fields.keys[list_exception.index]
            message = "Deserialization failed because of field #{field} ('#{list_exception.element_exception}')"
          else
            field = nil
            message = "Deserialization failed because of underlying list ('#{list_exception}')"
          end
        end

        super(message, serial)

        @sedes = sedes
        @field = field
        @list_exception = list_exception
      end
    end
  end

  module Utils
    class <<self
      ##
      # Do your best to make `obj` as immutable as possible.
      #
      # If `obj` is a list, apply this function recursively to all elements and
      # return a new list containing them. If `obj` is an instance of
      # {RLP::Sedes::Serializable}, apply this function to its fields, and set
      # `@_mutable` to `false`. If `obj` is neither of the above, just return
      # `obj`.
      #
      # @return [Object] `obj` after making it immutable
      #
      def make_immutable!(obj)
        if obj.is_a?(Sedes::Serializable)
          obj.make_immutable!
        elsif list?(obj)
          obj.map {|e| make_immutable!(e) }
        else
          obj
        end
      end
    end

    extend self

    def primitive?(item)
      item.instance_of?(String)
    end

    def list?(item)
      !primitive?(item) && item.respond_to?(:each)
    end

    def bytes_to_str(v)
      v.unpack('U*').pack('U*')
    end

    def str_to_bytes(v)
      bytes?(v) ? v : v.b
    end

    def big_endian_to_int(v)
      v.unpack('H*').first.to_i(16)
    end

    def int_to_big_endian(v)
      hex = v.to_s(16)
      if hex.size % 2 == 1 
        hex = "0#{hex}"
      end
      [hex].pack('H*')
    end

    def encode_hex(b)
      raise TypeError, "Value must be an instance of String" unless b.instance_of?(String)
      b.unpack("H*").first
    end

    # TODO
    def decode_hex(s)
      raise TypeError, "Value must be an instance of string" unless s.instance_of?(String)
      # raise TypeError, 'Non-hexadecimal digit found' unless s =~ /\A[0-9a-fA-F]*\z/
      [s].pack("H*")
    end

    # BINARY_ENCODING = 'ASCII-8BIT'.freeze
    def bytes?(s)
      s && s.instance_of?(String) #&& s.encoding.name == BINARY_ENCODING
    end
  end

  module Sedes

    class <<self
      ##
      # Try to find a sedes objects suitable for a given Ruby object.
      #
      # The sedes objects considered are `obj`'s class, `big_endian_int` and
      # `binary`. If `obj` is a list, a `RLP::Sedes::List` will be constructed
      # recursively.
      #
      # @param obj [Object] the Ruby object for which to find a sedes object
      #
      # @raise [TypeError] if no appropriate sedes could be found
      #
      def infer(obj)
        return obj.class if sedes?(obj.class)
        return big_endian_int if obj.is_a?(Integer) && obj >= 0
        return binary if Binary.valid_type?(obj)
        return List.new(obj.map {|item| infer(item) }) if RLP.list?(obj)

        raise TypeError, "Did not find sedes handling type #{obj.class.name}"
      end

      def sedes?(obj)
        obj.respond_to?(:serialize) && obj.respond_to?(:deserialize)
      end

      def big_endian_int
        @big_endian_int ||= BigEndianInt.new
      end

      def binary
        @binary ||= Binary.new
      end

      def raw
        @raw ||= Raw.new
      end
    end
    
    class BigEndianInt
      include RLP::Constant
      include RLP::Error
      include Utils

      def initialize(size=nil)
        @size = size
      end

      def serialize(obj)
        raise SerializationError.new("Can only serialize integers", obj) unless obj.is_a?(Integer) or obj.is_a?(Bignum)
        raise SerializationError.new("Cannot serialize negative integers", obj) if obj < 0

        if @size && obj >= 256**@size
          msg = "Integer too large (does not fit in #{@size} bytes)"
          raise SerializationError.new(msg, obj)
        end

        s = obj == 0 ? BYTE_EMPTY : int_to_big_endian(obj)

        @size ? "#{BYTE_ZERO * [0, @size-s.size].max}#{s}" : s
      end

      def deserialize(serial)
        raise DeserializationError.new("Invalid serialization (wrong size)", serial) if @size && serial.size != @size
        raise DeserializationError.new("Invalid serialization (not minimal length)", serial) if !@size && serial.size > 0 && serial[0] == BYTE_ZERO

        serial = serial || BYTE_ZERO
        big_endian_to_int(serial)
      end
    end

    class Binary
      include Error
      include Utils

      Infinity = 1.0 / 0.0

      class <<self
        def fixed_length(l, allow_empty = false)
          new(l, l, allow_empty)
        end

        def valid_type?(obj)
          obj.instance_of?(String)
        end
      end

      def initialize(min_length = 0, max_length = Infinity, allow_empty = false)
        @min_length = min_length
        @max_length = max_length
        @allow_empty = allow_empty
      end

      def serialize(obj)
        raise SerializationError.new("Object is not a serializable (#{obj.class})", obj) unless self.class.valid_type?(obj)

        serial = str_to_bytes obj
        raise SerializationError.new("Object has invalid length", serial) unless valid_length?(serial.size)

        serial
      end

      def deserialize(serial)
        raise DeserializationError.new("Objects of type #{serial.class} cannot be deserialized", serial) unless primitive?(serial)
        raise DeserializationError.new("#{serial.class} has invalid length", serial) unless valid_length?(serial.size)

        serial
      end

      private

      def valid_length?(len)
        (@min_length <= len && len <= @max_length) ||
          (@allow_empty && len == 0)
      end

    end

    ##
    # A sedes for lists of arbitrary length.
    #
    class CountableList
      include Error
      include Utils

      def initialize(element_sedes, max_length = nil)
        @element_sedes = element_sedes
        @max_length = max_length
      end

      def serialize(obj)
        raise ListSerializationError.new("Can only serialize sequences", obj) unless list?(obj)

        result = []
        obj.each_with_index do |e, i|
          begin
            result.push @element_sedes.serialize(e)
          rescue SerializationError => e
            raise ListSerializationError.new(nil, obj, e, i)
          end

          if @max_length && result.size > @max_length
            msg = "Too many elements (#{result.size}, allowed #{@max_length})"
            raise ListSerializationError.new(msg, obj)
          end
        end

        result
      end

      def deserialize(serial)
        raise ListDeserializationError.new('Can only deserialize sequences', serial) unless list?(serial)

        result = []
        serial.each_with_index do |e, i|
          begin
            if @element_sedes.instance_of?(Class) && @element_sedes.include?(Sedes::Serializable)
              result.push @element_sedes.deserialize(e, {})
            else
              result.push @element_sedes.deserialize(e)
            end
          rescue DeserializationError => e
            raise ListDeserializationError.new(nil, serial, e, i)
          end

          if @max_length && result.size > @max_length
            msg = "Too many elements (#{result.size}, allowed #{@max_length})"
            raise ListDeserializationError.new(msg, serial)
          end
        end

        result.freeze
      end
    end

    ##
    # A sedes for lists of fixed length
    #
    class List
      include Error
      include Utils
      include Enumerable

      attr :elements, :strict

      def initialize(elements = [], strict = true)
        
        @strict = strict
        @elements = []

        elements.each do |e|
          if Sedes.sedes?(e)
            @elements.push e
          elsif list?(e)
            @elements.push List.new(e)
          else
            raise TypeError, "Instances of List must only contain sedes objects or nested sequences thereof."
          end
        end
      end

      def serialize(obj)
        raise ListSerializationError.new("Can only serialize sequences", obj) unless list?(obj)
        raise ListSerializationError.new("List has wrong length", obj) if (@strict && self.elements.size != obj.size) || self.elements.size < obj.size

        result = []
        obj.zip(self.elements).each_with_index do |element_sedes, i|
          element = element_sedes[0]
          sedes = element_sedes[1]
          begin
            result.push sedes.serialize(element)
          rescue SerializationError => e
            raise ListSerializationError.new(nil, obj, e, i)
          end
        end

        result
      end

      def deserialize(serial)
        raise ListDeserializationError.new('Can only deserialize sequences', serial) unless list?(serial)
        raise ListDeserializationError.new('List has wrong length', serial) if @strict && serial.size != self.elements.size

        result = []

        len = [serial.size, self.elements.size].min
        len.times do |i|
          begin
            sedes = self.elements[i]
            element = serial[i]
            
            if sedes.instance_of?(Class) && sedes.include?(Sedes::Serializable)
              result.push sedes.deserialize(element, {})
            else
              result.push sedes.deserialize(element)
            end
          rescue DeserializationError => e
            raise ListDeserializationError.new(nil, serial, e, i)
          end
        end

        result.freeze
      end

      def <<(val)
        self.elements << val
      end

      def each(&block)
        self.elements.each(&block)
      end
    end

    ##
    # A sedes that does nothing. Thus, everything that can be directly encoded
    # by RLP is serializable. This sedes can be used as a placeholder when
    # deserializing larger structures.
    #
    class Raw
      include Error
      include Utils

      def serialize(obj)
        raise SerializationError.new("Can only serialize nested lists of strings", obj) unless serializable?(obj)
        obj
      end

      def deserialize(serial)
        serial
      end

      private

      def serializable?(obj)
        return true if primitive?(obj)
        return obj.all? {|item| serializable?(item) } if list?(obj)
        false
      end

    end

    ##
    # Mixin for objects which can be serialized into RLP lists.
    #
    # `fields` defines which attributes are serialized and how this is done. It
    # is expected to be a hash in the form of `name => sedes`. Here, `name` is
    # the name of an attribute and `sedes` is the sedes object that will be used
    # to serialize the corresponding attribute. The object as a whole is then
    # serialized as a list of those fields.
    #
    module Serializable

      module ClassMethods
        include Error

        def set_serializable_fields(fields)
          raise "Cannot override serializable fields!" if @serializable_fields
          @serializable_fields = {} # always reset
          fields.each {|name, sedes| add_serializable_field name, sedes }
        end

        def add_serializable_field(name, sedes)
          unless @serializable_fields
            # append or reset
            @serializable_fields = superclass.include?(Sedes::Serializable) ? superclass.serializable_fields.dup : {}
          end

          @serializable_fields[name] = sedes
        end

        def inherit_serializable_fields!
          @serializable_fields = superclass.serializable_fields
        end

        def serializable_fields
          @serializable_fields
        end

        def serializable_sedes
          @serializable_sedes ||= Sedes::List.new(serializable_fields.values)
        end

        def serialize(obj)
          begin
            field_values = serializable_fields.keys.map {|k| obj.send k }
          rescue NoMethodError => e
            raise ObjectSerializationError.new("Cannot serialize this object (missing attribute)", obj)
          end

          begin
            serializable_sedes.serialize(field_values)
          rescue ListSerializationError => e
            raise ObjectSerializationError.new(nil, obj, self, e)
          end
        end

        def deserialize(serial, options)
          exclude = options.delete(:exclude)

          begin
            values = serializable_sedes.deserialize(serial)
          rescue ListDeserializationError => e
            raise ObjectDeserializationError.new(nil, serial, self, e)
          end

          params = Hash[*serializable_fields.keys.zip(values).flatten(1)]
          params.delete_if {|field, value| exclude.include?(field) } if exclude

          obj = self.new params.merge(options)
          obj.instance_variable_set :@_mutable, false
          obj
        end

        ##
        # Create a new sedes considering only a reduced set of fields.
        #
        def exclude(excluded_fields)
          fields = serializable_fields.dup.delete_if {|k, v| excluded_fields.include?(k) }
          Class.new(self).tap {|cls| cls.set_serializable_fields fields }
        end
      end

      class <<self
        def included(base)
          base.extend ClassMethods
        end
      end

      attr_accessor :_cached_rlp

      def initialize(*args)
        serializable_initialize parse_field_args(args)
      end

      ##
      # Mimic python's argument syntax, accept both normal arguments and named
      # arguments. Normal argument overrides named argument.
      #
      def parse_field_args(args)
        h = {}

        options = args.last.is_a?(Hash) ? args.pop : {}
        field_set = self.class.serializable_fields.keys

        fields = self.class.serializable_fields.keys[0,args.size]
        fields.zip(args).each do |field, arg|
          h[field] = arg
          field_set.delete field
        end

        options.each do |field, value|
          if field_set.include?(field)
            h[field] = value
            field_set.delete field
          end
        end

        h
      end

      def serializable_initialize(fields)
        make_mutable!

        field_set = self.class.serializable_fields.keys
        fields.each do |field, value|
          _set_field field, value
          field_set.delete field
        end

        # raise ArgumentError, "xxxxxxxxxxxx #{field_set.size}"

        unless field_set.size == 0
          raise TypeError, "Not all fields initialized. Missing: #{field_set}"
        end
      end

      def _set_field(field, value)
        make_mutable! unless instance_variable_defined?(:@_mutable)

        if mutable? || !self.class.serializable_fields.has_key?(field)
          instance_variable_set :"@#{field}", value
        else
          raise ArgumentError, "Tried to mutate immutable object"
        end
      end

      def ==(other)
        return false unless other.class.respond_to?(:serialize)
        self.class.serialize(self) == other.class.serialize(other)
      end

      def mutable?
        @_mutable
      end

      def make_immutable!
        make_mutable!
        self.class.serializable_fields.keys.each do |field|
          ::RLP::Utils.make_immutable! send(field)
        end

        @_mutable = false
        self
      end

      def make_mutable!
        @_mutable = true
      end

    end
  end

  module Encode
    include Constant
    include Error
    include Utils

    ##
    # Encode a Ruby object in RLP format.
    #
    # By default, the object is serialized in a suitable way first (using
    # {RLP::Sedes.infer}) and then encoded. Serialization can be explicitly
    # suppressed by setting {RLP::Sedes.infer} to `false` and not passing an
    # alternative as `sedes`.
    #
    # If `obj` has an attribute `_cached_rlp` (as, notably,
    # {RLP::Serializable}) and its value is not `nil`, this value is returned
    # bypassing serialization and encoding, unless `sedes` is given (as the
    # cache is assumed to refer to the standard serialization which can be
    # replaced by specifying `sedes`).
    #
    # If `obj` is a {RLP::Serializable} and `cache` is true, the result of the
    # encoding will be stored in `_cached_rlp` if it is empty and
    # {RLP::Serializable.make_immutable} will be invoked on `obj`.
    #
    # @param obj [Object] object to encode
    # @param sedes [#serialize(obj)] an object implementing a function
    #   `serialize(obj)` which will be used to serialize `obj` before
    #   encoding, or `nil` to use the infered one (if any)
    # @param infer_serializer [Boolean] if `true` an appropriate serializer
    #   will be selected using {RLP::Sedes.infer} to serialize `obj` before
    #   encoding
    # @param cache [Boolean] cache the return value in `obj._cached_rlp` if
    #   possible and make `obj` immutable (default `false`)
    #
    # @return [String] the RLP encoded item
    #
    # @raise [RLP::EncodingError] in the rather unlikely case that the item
    #   is too big to encode (will not happen)
    # @raise [RLP::SerializationError] if the serialization fails
    #
    def encode(obj, sedes = nil, infer_serializer = true, cache = false)
      return obj._cached_rlp if obj.is_a?(Sedes::Serializable) && obj._cached_rlp && sedes.nil?

      really_cache = obj.is_a?(Sedes::Serializable) && sedes.nil? && cache

      if sedes
        item = sedes.serialize(obj)
      elsif infer_serializer
        item = Sedes.infer(obj).serialize(obj)
      else
        item = obj
      end

      result = encode_raw(item)

      if really_cache
        obj._cached_rlp = result
        obj.make_immutable!
      end

      result
    end

    private

    def encode_raw(item)
      return item if item.instance_of?(RLP::Data)
      return encode_primitive(item) if primitive?(item)
      return encode_list(item) if list?(item)

      msg = "Cannot encode object of type #{item.class.name}"
      raise EncodingError.new(msg, item)
    end

    def encode_primitive(item)
      return str_to_bytes(item) if item.size == 1 && item.ord < PRIMITIVE_PREFIX_OFFSET

      payload = str_to_bytes item
      prefix = length_prefix payload.size, PRIMITIVE_PREFIX_OFFSET

      "#{prefix}#{payload}"
    end

    def encode_list(list)
      payload = list.map {|item| encode_raw(item) }.join
      prefix = length_prefix payload.size, LIST_PREFIX_OFFSET

      "#{prefix}#{payload}"
    end

    def length_prefix(length, offset)
      if length < SHORT_LENGTH_LIMIT
        (offset+length).chr
      elsif length < LONG_LENGTH_LIMIT
        length_string = int_to_big_endian(length)
        length_len = (offset + SHORT_LENGTH_LIMIT - 1 + length_string.size).chr
        "#{length_len}#{length_string}"
      else
        raise ArgumentError, "Length greater than 256**8"
      end
    end
  end

  module Decode
    include Constant
    include Error
    include Utils

    ##
    # Decode an RLP encoded object.
    #
    # If the deserialized result `obj` has an attribute `_cached_rlp` (e.g. if
    # `sedes` is a subclass of {RLP::Sedes::Serializable}), it will be set to
    # `rlp`, which will improve performance on subsequent {RLP::Encode#encode}
    # calls. Bear in mind however that `obj` needs to make sure that this value
    # is updated whenever one of its fields changes or prevent such changes
    # entirely ({RLP::Sedes::Serializable} does the latter).
    #
    # @param options (Hash) deserialization options:
    #
    #   * sedes (Object) an object implementing a function `deserialize(code)`
    #     which will be applied after decoding, or `nil` if no deserialization
    #     should be performed
    #   * strict (Boolean) if false inputs that are longer than necessary don't
    #     cause an exception
    #   * (any options left) (Hash) additional keyword arguments passed to the
    #     deserializer
    #
    # @return [Object] the decoded and maybe deserialized object
    #
    # @raise [RLP::Error::DecodingError] if the input string does not end after
    #   the root item and `strict` is true
    # @raise [RLP::Error::DeserializationError] if the deserialization fails
    #
    def decode(rlp, options)
      rlp = str_to_bytes(rlp)
      sedes = options.delete(:sedes)
      strict = options.has_key?(:strict) ? options.delete(:strict) : true

      begin
        item, next_start = consume_item(rlp, 0)
      rescue Exception => e
        raise DecodingError.new("Cannot decode rlp string: #{e}", rlp)
      end

      raise DecodingError.new("RLP string ends with #{rlp.size - next_start} superfluous bytes", rlp) if next_start != rlp.size && strict

      if sedes
        obj = sedes.instance_of?(Class) && sedes.include?(Sedes::Serializable) ?
          sedes.deserialize(item, options) :
          sedes.deserialize(item)

        if obj.respond_to?(:_cached_rlp)
          obj._cached_rlp = rlp
          raise "RLP::Sedes::Serializable object must be immutable after decode" if obj.is_a?(Sedes::Serializable) && obj.mutable?
        end

        obj
      else
        item
      end
    end

    def descend(rlp, *path)
      rlp = str_to_bytes(rlp)

      path.each do |pa|
        pos = 0

        type, _, pos = consume_length_prefix rlp, pos
        raise DecodingError.new("Trying to descend through a non-list!", rlp) if type != :list

        pa.times do |i|
          _, l, s = consume_length_prefix(rlp, pos)
          pos = l + s
        end

        _, l, s = consume_length_prefix rlp, pos
        rlp = rlp[pos...(l+s)]
      end

      rlp
    end

    def append(rlp, obj)
      type, _, pos = consume_length_prefix rlp, 0
      raise DecodingError.new("Trying to append to a non-list!", rlp) if type != :list

      rlpdata = rlp[pos..-1] + RLP.encode(obj)
      prefix = length_prefix rlpdata.size, LIST_PREFIX_OFFSET

      prefix + rlpdata
    end

    def insert(rlp, index, obj)
      type, _, pos = consume_length_prefix rlp, 0
      raise DecodingError.new("Trying to insert to a non-list!", rlp) if type != :list

      beginpos = pos
      index.times do |i|
        _, _len, _pos = consume_length_prefix rlp, pos
        pos = _pos + _len
        break if _pos >= rlp.size
      end

      rlpdata = rlp[beginpos...pos] + RLP.encode(obj) + rlp[pos..-1]
      prefix = length_prefix rlpdata.size, LIST_PREFIX_OFFSET

      prefix + rlpdata
    end

    def pop(rlp, index=2**50)
      type, _, pos = consume_length_prefix rlp, 0
      raise DecodingError.new("Trying to pop from a non-list!", rlp) if type != :list

      beginpos = pos
      index.times do |i|
        _, _len, _pos = consume_length_prefix rlp, pos
        break if _len + _pos >= rlp.size
        pos = _len + _pos
      end

      _, _len, _pos = consume_length_prefix rlp, pos
      rlpdata = rlp[beginpos...pos] + rlp[(_len+_pos)..-1]
      prefix = length_prefix rlpdata.size, LIST_PREFIX_OFFSET

      prefix + rlpdata
    end

    def compare_length(rlp, length)
      type, len, pos = consume_length_prefix rlp, 0
      raise DecodingError.new("Trying to compare length of non-list!", rlp) if type != :list

      return (length == 0 ? 0 : -length/length.abs) if rlp == EMPTYLIST

      len = 0
      loop do
        return 1 if len > length

        _, _len, _pos = consume_length_prefix rlp, pos
        len += 1

        break if _len + _pos >= rlp.size
        pos = _len + _pos
      end

      len == length ? 0 : -1
    end

    ##
    # Read an item from an RLP string.
    #
    # * `rlp` - the string to read from
    # * `start` - the position at which to start reading`
    #
    # Returns a pair `[item, end]` where `item` is the read item and `end` is
    # the position of the first unprocessed byte.
    #
    def consume_item(rlp, start)
      t, l, s = consume_length_prefix(rlp, start)
      consume_payload(rlp, s, t, l)
    end

    ##
    # Read a length prefix from an RLP string.
    #
    # * `rlp` - the rlp string to read from
    # * `start` - the position at which to start reading
    #
    # Returns an array `[type, length, end]`, where `type` is either `:str`
    # or `:list` depending on the type of the following payload, `length` is
    # the length of the payload in bytes, and `end` is the position of the
    # first payload byte in the rlp string (thus the end of length prefix).
    #
    def consume_length_prefix(rlp, start)
      b0 = rlp[start].ord

      if b0 < PRIMITIVE_PREFIX_OFFSET # single byte
        [:str, 1, start]
      elsif b0 < PRIMITIVE_PREFIX_OFFSET + SHORT_LENGTH_LIMIT # short string
        raise DecodingError.new("Encoded as short string although single byte was possible", rlp) if (b0 - PRIMITIVE_PREFIX_OFFSET == 1) && rlp[start+1].ord < PRIMITIVE_PREFIX_OFFSET

        [:str, b0 - PRIMITIVE_PREFIX_OFFSET, start + 1]
      elsif b0 < LIST_PREFIX_OFFSET # long string
        raise DecodingError.new("Length starts with zero bytes", rlp) if rlp.slice(start+1) == BYTE_ZERO

        ll = b0 - PRIMITIVE_PREFIX_OFFSET - SHORT_LENGTH_LIMIT + 1
        l = big_endian_to_int rlp[(start+1)...(start+1+ll)]
        raise DecodingError.new('Long string prefix used for short string', rlp) if l < SHORT_LENGTH_LIMIT

        [:str, l.to_fix, start+1+ll]
      elsif b0 < LIST_PREFIX_OFFSET + SHORT_LENGTH_LIMIT # short list
        [:list, b0 - LIST_PREFIX_OFFSET, start + 1]
      else # long list
        raise DecodingError.new('Length starts with zero bytes', rlp) if rlp.slice(start+1) == BYTE_ZERO

        ll = b0 - LIST_PREFIX_OFFSET - SHORT_LENGTH_LIMIT + 1
        l = big_endian_to_int rlp[(start+1)...(start+1+ll)]
        raise DecodingError.new('Long list prefix used for short list', rlp) if l < SHORT_LENGTH_LIMIT

        [:list, l.to_fix, start+1+ll]
      end
    end

    ##
    # Read the payload of an item from an RLP string.
    #
    # * `rlp` - the rlp string to read from
    # * `type` - the type of the payload (`:str` or `:list`)
    # * `start` - the position at which to start reading
    # * `length` - the length of the payload in bytes
    #
    # Returns a pair `[item, end]`, where `item` is the read item and `end` is
    # the position of the first unprocessed byte.
    #
    def consume_payload(rlp, start, type, length)
      case type
      when :str
        [rlp[start...(start+length)], start+length]
      when :list
        items = []
        next_item_start = start
        payload_end = next_item_start + length

        while next_item_start < payload_end
          item, next_item_start = consume_item rlp, next_item_start
          items.push item
        end

        raise DecodingError.new('List length prefix announced a too small length', rlp) if next_item_start > payload_end

        [items, next_item_start]
      else
        raise TypeError, 'Type must be either :str or :list'
      end
    end
  end

  include Encode
  include Decode

  extend self

  EMPTYLIST = encode([]).freeze
end
  