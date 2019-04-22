
include RLP
include RLP::Utils

##################
# Helper Methods #
##################

def to_bytes(v)
  if v.instance_of?(String)
    RLP.str_to_bytes(v)
  elsif v.instance_of?(Array)
    v.map {|item| to_bytes(item) }
  else
    v
  end
end

def code_array_to_bytes(code_array)
  code_array.pack('C*')
end


@@rlptest = {
	"emptystring": {
		"in": "", 
		"out": "80"
	},
	"shortstring": {
		"in": "dog", 
		"out": "83646f67"
    },
	"shortstring2": {
		"in": "Lorem ipsum dolor sit amet, consectetur adipisicing eli", 
		"out": "b74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69"
	},
	"longstring": {
		"in": "Lorem ipsum dolor sit amet, consectetur adipisicing elit", 
		"out": "b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974"
	},
	"longstring2": {
	"in": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur mauris magna, suscipit sed vehicula non, iaculis faucibus tortor. Proin suscipit ultricies malesuada. Duis tortor elit, dictum quis tristique eu, ultrices at risus. Morbi a est imperdiet mi ullamcorper aliquet suscipit nec lorem. Aenean quis leo mollis, vulputate elit varius, consequat enim. Nulla ultrices turpis justo, et posuere urna consectetur nec. Proin non convallis metus. Donec tempor ipsum in mauris congue sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse convallis sem vel massa faucibus, eget lacinia lacus tempor. Nulla quis ultricies purus. Proin auctor rhoncus nibh condimentum mollis. Aliquam consequat enim at metus luctus, a eleifend purus egestas. Curabitur at nibh metus. Nam bibendum, neque at auctor tristique, lorem libero aliquet arcu, non interdum tellus lectus sit amet eros. Cras rhoncus, metus ac ornare cursus, dolor justo ultrices metus, at ullamcorper volutpat", 
		"out": "b904004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e20437572616269747572206d6175726973206d61676e612c20737573636970697420736564207665686963756c61206e6f6e2c20696163756c697320666175636962757320746f72746f722e2050726f696e20737573636970697420756c74726963696573206d616c6573756164612e204475697320746f72746f7220656c69742c2064696374756d2071756973207472697374697175652065752c20756c7472696365732061742072697375732e204d6f72626920612065737420696d70657264696574206d6920756c6c616d636f7270657220616c6971756574207375736369706974206e6563206c6f72656d2e2041656e65616e2071756973206c656f206d6f6c6c69732c2076756c70757461746520656c6974207661726975732c20636f6e73657175617420656e696d2e204e756c6c6120756c74726963657320747572706973206a7573746f2c20657420706f73756572652075726e6120636f6e7365637465747572206e65632e2050726f696e206e6f6e20636f6e76616c6c6973206d657475732e20446f6e65632074656d706f7220697073756d20696e206d617572697320636f6e67756520736f6c6c696369747564696e2e20566573746962756c756d20616e746520697073756d207072696d697320696e206661756369627573206f726369206c756374757320657420756c74726963657320706f737565726520637562696c69612043757261653b2053757370656e646973736520636f6e76616c6c69732073656d2076656c206d617373612066617563696275732c2065676574206c6163696e6961206c616375732074656d706f722e204e756c6c61207175697320756c747269636965732070757275732e2050726f696e20617563746f722072686f6e637573206e69626820636f6e64696d656e74756d206d6f6c6c69732e20416c697175616d20636f6e73657175617420656e696d206174206d65747573206c75637475732c206120656c656966656e6420707572757320656765737461732e20437572616269747572206174206e696268206d657475732e204e616d20626962656e64756d2c206e6571756520617420617563746f72207472697374697175652c206c6f72656d206c696265726f20616c697175657420617263752c206e6f6e20696e74657264756d2074656c6c7573206c65637475732073697420616d65742065726f732e20437261732072686f6e6375732c206d65747573206163206f726e617265206375727375732c20646f6c6f72206a7573746f20756c747269636573206d657475732c20617420756c6c616d636f7270657220766f6c7574706174"
	},
	"zero": {
		"in": "", 
		"out": "80"
	},
	"smallint": {
		"in": 1, 
		"out": "01"
	},
	"smallint2": {
		"in": 16, 
		"out": "10"
	},
	"smallint3": {
		"in": 79, 
		"out": "4f"
	},
	"smallint4": {
		"in": 127, 
		"out": "7f"
	},
	"mediumint1": {
		"in": 128, 
		"out": "8180"
	},
	"mediumint2": {
		"in": 1000, 
		"out": "8203e8"
	},
	"mediumint3": {
		"in": 100000, 
		"out": "830186a0"
	},
	"mediumint4": {
		"in": "83729609699884896815286331701780722".to_big, 
		"out": "8F102030405060708090A0B0C0D0E0F2"
	},
	"mediumint5": {
		"in": "105315505618206987246253880190783558935785933862974822347068935681".to_big,
		"out": "9C0100020003000400050006000700080009000A000B000C000D000E01"
	},
	"emptylist": {
		"in": [], 
		"out": "c0"
	},
	"stringlist": {
		"in": [ "dog", "god", "cat" ],
		"out": "cc83646f6783676f6483636174"
	},
	"multilist": {
		"in": [ "zw", [ 4 ], 1 ], 
		"out": "c6827a77c10401"
	},
	"shortListMax1": {
		"in": [ "asdf", "qwer", "zxcv", "asdf","qwer", "zxcv", "asdf", "qwer", "zxcv", "asdf", "qwer"],
		"out": "F784617364668471776572847a78637684617364668471776572847a78637684617364668471776572847a78637684617364668471776572"
	},
	"longList1": { 
		"in": [
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"]
		], 
		"out": "F840CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376"
	},
	"longList2": { 
		"in": [
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"],
			["asdf","qwer","zxcv"]
		], 
		"out": "F90200CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376CF84617364668471776572847a786376"
	},

	"listsoflists": {
		"in": [ [ [], [] ], [] ], 
		"out": "c4c2c0c0c0"
	},
	"listsoflists2": {
		"in": [ [], [[]], [ [], [[]] ] ], 
		"out": "c7c0c1c0c3c0c1c0"
	},
	"dictTest1": { 
		"in": [ 
			["key1", "val1"], 
			["key2", "val2"], 
			["key3", "val3"],
			["key4", "val4"]
		],
		"out": "ECCA846b6579318476616c31CA846b6579328476616c32CA846b6579338476616c33CA846b6579348476616c34"
	},
	"bigint": {
		"in": "115792089237316195423570985008687907853269984665640564039457584007913129639936".to_big,
		"out": "a1010000000000000000000000000000000000000000000000000000000000000000"
	}
}

@@random_integers = [256, 257, 4839, 849302, "483290432".to_big, "483290483290482039482039".to_big,
                      "48930248348219540325894323584235894327865439258743754893066".to_big]

assert("test_negative_int") do
  negative_int = [-1, -100, -255, -256, -2342423]
  negative_int.each do |n|
    assert_raise(SerializationError) { Sedes.big_endian_int.serialize(n) }
  end
end

assert("test_serialization") do
  assert_true @@random_integers[-1] < 2**256

  @@random_integers.each do |n|
    serial = Sedes.big_endian_int.serialize(n)
    deserial = Sedes.big_endian_int.deserialize(serial)
    assert_equal n, deserial
    assert_true serial[0] != "\x00" if n != 0
  end
end

assert("test_single_byte") do
  (0...256).each do |n|
    # TODO
    if n == 11 or n == 13 or n == 0
      next
    end
    c = n.chr

    serial = Sedes.big_endian_int.serialize(n)
    assert_equal c, serial

    deserial = Sedes.big_endian_int.deserialize(serial)
    assert_equal n, deserial
  end
end

assert("test_valid_data") do
  [ [256, str_to_bytes("\x01\x00")],
    [1024, str_to_bytes("\x04\x00")],
    [65535, str_to_bytes("\xFF\xFF")]
  ].each do |n, s|
    serial = Sedes.big_endian_int.serialize(n)
    deserial = Sedes.big_endian_int.deserialize(serial)
    assert_equal s, serial
    assert_equal n, deserial
  end
end

assert("test_fixed_length") do
  s = Sedes::BigEndianInt.new(4)

  [0, 1, 255, 256, 256**3, 256**4 - 1].each do |i|
    assert_equal 4, s.serialize(i).size
    assert_equal i, s.deserialize(s.serialize(i))
  end

  [256**4, 256**4 + 1, 256**5, (-1 - 256), 'asdf'].each do |i|
    assert_raise(SerializationError) { s.serialize(i) }
  end
end

assert("test_coordinate_with_list") do
  l1 = Sedes::List.new
  l2 = Sedes::List.new [Sedes.big_endian_int, Sedes.big_endian_int]

  c = Sedes::CountableList.new Sedes.big_endian_int

  assert_equal [].freeze, l1.deserialize(c.serialize([]))

  [[1], [1,2,3], 0...30, [4,3]].each do |l|
    s = c.serialize l
    assert_raise(DeserializationError) { l1.deserialize(s) }
  end

  [[1,2], [3,4], [9,8]].each do |v|
    s = c.serialize(v)
    assert_equal v, l2.deserialize(s)
  end

  [[], [1], [1,2,3]].each do |v|
    assert_raise(DeserializationError) { l2.deserialize(c.serialize(v)) }
  end
end

assert("test_countable_list_sedes") do
  l1 = Sedes::CountableList.new Sedes.big_endian_int

  # TODO: fixed (0...500) -> (14...500)
  [[], [1,2], (14...500).to_a].each do |s|
    assert_equal s, l1.deserialize(l1.serialize(s))
  end

  [[1, 'asdf'], ['asdf'], [1, [2]], [[]]].each do |n|
    assert_raise(SerializationError) { l1.serialize(n) }
  end

  l2 = Sedes::CountableList.new Sedes::CountableList.new(Sedes.big_endian_int)

  [[], [[]], [[1,2,3], [4]], [[5], [6,7,8]], [[9,1]]].each do |s|
    assert_equal s, l2.deserialize(l2.serialize(s))
  end

  [[[[]]], [1,2], [1, ['asdf'], ['fdsa']]].each do |n|
    assert_raise(SerializationError) { l2.serialize(n) }
  end

  l3 = Sedes::CountableList.new Sedes.big_endian_int, 3

  [[], [1], [1,2], [1,2,3]].each do |s|
    serial = l3.serialize(s)
    assert_equal l1.serialize(s), serial
    assert_equal s, l3.deserialize(serial)
  end

  [[1,2,3,4], [1,2,3,4,5,6,7], (14...500).to_a].each do |n|
    assert_raise(SerializationError) { l3.serialize(n) }

    serial = l1.serialize(n)
    assert_raise(DeserializationError) { l3.deserialize(serial) }
  end
end

assert("test_list_sedes") do
  l1 = Sedes::List.new
  l2 = Sedes::List.new [Sedes.big_endian_int, Sedes.big_endian_int]
  l3 = Sedes::List.new [l1, l2, [[[]]]]

  assert_raise(SerializationError) { l1.serialize([[]]) }
  assert_raise(SerializationError) { l1.serialize([5]) }

  [[], [1,2,3], [1, [2,3], 4]].each do |d|
    assert_raise(SerializationError) { l2.serialize(d) }
  end

  [[], [[], [], [[[]]]], [[], [5,6], [[]]]].each do |d|
    assert_raise(SerializationError) { l3.serialize(d) }
  end
end

assert("test_raw_sedes") do
  [
    '',
    'asdf',
    'fds89032#$@%',
    'dfsa',
    ['dfsa', ''],
    [],
    ['fdsa', ['dfs', ['jfdkl']]]
  ].each do |s|
    Sedes.raw.serialize(s)
    code = encode(s, Sedes.raw)
    assert_equal s, decode(code, { sedes: Sedes.raw })
  end

  [
    0,
    32,
    ['asdf', ['fdsa', [5]]],
    String
  ].each do |n|
    assert_raise(SerializationError) { Sedes.raw.serialize(n) }
  end
end

class Test1
  include RLP::Sedes::Serializable

  set_serializable_fields(
    field1: RLP::Sedes.big_endian_int,
    field2: RLP::Sedes.binary,
    field3: RLP::Sedes::List.new([
      RLP::Sedes.big_endian_int,
      RLP::Sedes.binary
    ])
  )

  def field1
    @field1
  end

  def field1=(v)
    _set_field(:field1, v)
  end

  def field2
    @field2
  end

  def field2=(v)
    _set_field(:field2, v)
  end

  def field3
    @field3
  end

  def field3=(v)
    _set_field(:field3, v)
  end
end

class Test2
  include RLP::Sedes::Serializable

  set_serializable_fields(
    field1: Test1,
    field2: RLP::Sedes::List.new([Test1, Test1])
  )

  def field1
    @field1
  end

  def field1=(v)
    _set_field(:field1, v)
  end

  def field2
    @field2
  end

  def field2=(v)
    _set_field(:field2, v)
  end
end

assert("test_serializable") do
  t1a_data = [5, 'a', [1, '']]
  t1b_data = [9, 'b', [2, '']]

  t1a = Test1.new(*t1a_data)
  t1b = Test1.new(*t1b_data)
  t2  = Test2.new t1a, [t1a, t1b]

  # equality
  assert_true t1a != t1b
  assert_true t1b != t2
  assert_true t2  != t1a

  # # mutability
  t1a.field1 += 1
  t1a.field2 = 'x'
  assert_true 6, t1a.field1
  assert_true 'x', t1a.field2

  t1a.field1 -= 1
  t1a.field2 = 'a'
  assert_true 5, t1a.field1
  assert_true 'a', t1a.field2

  # inference
  assert_equal Test1, Sedes.infer(t1a)
  assert_equal Test1, Sedes.infer(t1b)
  assert_equal Test2, Sedes.infer(t2)

  # serialization
  assert_raise(SerializationError) { Test1.serialize(t2) }
  assert_raise(SerializationError) { Test2.serialize(t1a) }
  assert_raise(SerializationError) { Test2.serialize(t1b) }

  t1a_s = Test1.serialize t1a
  t1b_s = Test1.serialize t1b
  t2_s  = Test2.serialize t2
  assert_equal ["\x05", "a", ["\x01", ""]], t1a_s
  assert_equal ["\x09", "b", ["\x02", ""]], t1b_s
  assert_equal [t1a_s, [t1a_s, t1b_s]], t2_s

  # deserialization
  t1a_d = Test1.deserialize t1a_s, {}
  t1b_d = Test1.deserialize t1b_s, {}
  t2_d  = Test2.deserialize t2_s, {}
  assert_equal false, t1a_d.mutable?
  assert_equal false, t1b_d.mutable?
  assert_equal false, t2_d.mutable?

  [t1a_d, t1b_d].each do |obj|
    before1 = obj.field1
    before2 = obj.field2
    assert_raise(ArgumentError) { obj.field1 += 1 }
    assert_raise(ArgumentError) { obj.field2 = 'x' }
    assert_equal before1, obj.field1
    assert_equal before2, obj.field2
  end

  assert_equal t1a, t1a_d
  assert_equal t1b, t1b_d
  assert_equal t2,  t2_d

  # encoding and decoding
  [t1a, t1b, t2].each do |obj|
    rlp_code = encode obj

    assert_nil obj._cached_rlp
    assert_equal true, obj.mutable?

    assert_equal rlp_code, encode(obj, nil, true, true)
    assert_equal rlp_code, obj._cached_rlp
    assert_equal false, obj.mutable?

    assert_equal rlp_code, encode(obj)
    assert_equal rlp_code, obj._cached_rlp
    assert_equal false, obj.mutable?

    obj_decoded = decode rlp_code, sedes: obj.class
    assert_equal obj, obj_decoded
    assert_equal false, obj_decoded.mutable?
    assert_equal rlp_code, obj_decoded._cached_rlp
  end
end

assert("test_make_immutable") do
  list_m = []
  list_i = RLP::Utils.make_immutable! list_m
  assert_true list_m.object_id != list_i.object_id

  assert_equal 1, RLP::Utils.make_immutable!(1)
  assert_equal 'a', RLP::Utils.make_immutable!('a')
  assert_equal [1,2,3], RLP::Utils.make_immutable!([1,2,3])
  assert_equal [1,2,'a'], RLP::Utils.make_immutable!([1,2,'a'])
  assert_equal [[1],[2,[3],4],5,6], RLP::Utils.make_immutable!([[1], [2,[3],4],5,6])

  t1a_data = [5, 'a', [0, '']]
  t1b_data = [9, 'b', [2, '']]

  t1a = Test1.new(*t1a_data)
  t1b = Test1.new(*t1b_data)
  t2  = Test2.new t1a, [t1a, t1b]

  assert_equal true, t2.mutable?
  assert_equal true, t2.field1.mutable?
  assert_equal true, t2.field2[0].mutable?
  assert_equal true, t2.field2[1].mutable?

  t2.make_immutable!
  assert_equal false, t2.mutable?
  assert_equal false, t1a.mutable?
  assert_equal false, t1b.mutable?
  assert_equal t1a, t2.field1
  assert_equal [t1a, t1b], t2.field2

  t1a = Test1.new(*t1a_data)
  t1b = Test1.new(*t1b_data)
  t2  = Test2.new t1a, [t1a, t1b]

  assert_equal true, t2.mutable?
  assert_equal true, t2.field1.mutable?
  assert_equal true, t2.field2[0].mutable?
  assert_equal true, t2.field2[1].mutable?

  assert_equal [t1a, [t2, t1b]], RLP::Utils.make_immutable!([t1a, [t2, t1b]])

  assert_equal false, t2.mutable?
  assert_equal false, t1a.mutable?
  assert_equal false, t1b.mutable?
end

assert("test_create_new_sedes_excluding_some_fields") do
  cls = Test1.exclude [:field2]
  assert_equal Test1, cls.superclass
  assert_equal %i(field1 field3), cls.serializable_fields.keys
  assert_equal %i(field1 field2 field3), Test1.serializable_fields.keys
end

class Test3
  include RLP::Sedes::Serializable

  set_serializable_fields(
    field1: RLP::Sedes.big_endian_int
  )

  def field1
    @field1
  end

  def field1=(v)
    _set_field(:field1, v)
  end

  attr :bar

  def initialize(*args)
    field1 = args[0] if args[0].is_a?(Integer)
    options = args.last.instance_of?(Hash) ? args.last : {}

    field1 = options.delete(:field1) if options.has_key?(:field1)
    bar = options.delete(:bar) || 1

    @bar = bar
    super(field1)
  end
end

assert("test_deserialize_with_extra_arguments") do
  t = Test3.new(1, bar: 2)
  assert_equal 1, t.field1
  assert_equal 2, RLP.decode(RLP.encode(t), { sedes: Test3, bar: 2 }).bar
end

class Test4 < Test1
  add_serializable_field :field4, RLP::Sedes.big_endian_int
  add_serializable_field :field5, RLP::Sedes.big_endian_int

  def field4
    @field4
  end

  def field4=(v)
    _set_field(:field4, v)
  end

  def field5
    @field5
  end

  def field5=(v)
    _set_field(:field5, v)
  end
end

assert("test_inherit") do
  assert_equal %i(field1 field2 field3 field4 field5), Test4.serializable_fields.keys
end

assert("test_initialize_error_message") do
  t1a_data = [5, 'a', ]

  begin
    t1a = Test1.new(*t1a_data)
    Test1.serialize(t1a)
  rescue Exception => e
    assert_equal e.class, RLP::TypeError
    assert_equal e.message, "Not all fields initialized. Missing: [:field3]"
  end
end

assert("test_rlp_class_method") do
  bytes = code_array_to_bytes([0x00, 0x7f])
  assert_equal encode(bytes), RLP.encode(bytes)
end

assert("test_encode_short_string") do
  bytes = code_array_to_bytes([0x00, 0x7f])
  assert_equal str_to_bytes("\x82\x00\x7f"), encode(bytes)
end

assert("test_encode_with_pyrlp_fixtures") do
  fixtures = @@rlptest
  fixtures.each do |name, in_out|
    data = to_bytes in_out[:in]
    expect = in_out[:out].upcase
    result = encode_hex(encode(data)).upcase
    assert_equal result, expect, "Test #{name} failed (encoded #{data} to #{result} instead of #{expect})"
  end
end

assert("test_descend") do
  rlp = RLP.encode [1, [2, [3, [4, [5]]]]]

  assert_equal RLP.encode(1), RLP.descend(rlp, 0)
  assert_equal RLP.encode(2), RLP.descend(rlp, 1, 0)
  assert_equal RLP.encode(5), RLP.descend(rlp, 1, 1, 1, 1, 0)

  assert_equal RLP.encode([3,[4,[5]]]), RLP.descend(rlp, 1, 1)
  assert_equal RLP.encode([5]), RLP.descend(rlp, 1, 1, 1, 1)
end

assert("test_append") do
  rlp = RLP.encode [1, [2,3]]
  assert_equal RLP.encode([1, [2,3], 4]), RLP.append(rlp, 4)

  rlp = RLP.encode [1]
  assert_equal RLP.encode([1, [2,3], 4]), RLP.append(RLP.append(rlp, [2,3]), 4)
end

assert("test_insert") do
  rlp = RLP.encode [1, 2, 3]
  assert_equal RLP.encode([4, 1, 2, 3]), RLP.insert(rlp, 0, 4)
  assert_equal RLP.encode([1, 2, 3, 4]), RLP.insert(rlp, 3, 4)
  assert_equal RLP.encode([1, 2, 4, 3]), RLP.insert(rlp, 2, 4)
  assert_equal RLP.encode([1, 2, 5, 4, 3]), RLP.insert(RLP.insert(rlp, 2, 4), 2, 5)
end

assert("test_pop") do
  rlp = RLP.encode [1, 2, 3, 4, 5]
  assert_equal RLP.encode([2,3,4,5]), RLP.pop(rlp, 0)
  assert_equal RLP.encode([1,2,3,4]), RLP.pop(rlp, 4)
  assert_equal RLP.encode([1,2,4,5]), RLP.pop(rlp, 2)
  assert_equal RLP.encode([3,4,5]), RLP.pop(RLP.pop(rlp, 0), 0)
  assert_equal RLP.encode([1,2,3,4]), RLP.pop(rlp)
end

assert("test_compare_length") do
  rlp = RLP.encode [1,2,3,4,5]
  assert_equal (-1), RLP.compare_length(rlp, 100)
  assert_equal 1, RLP.compare_length(rlp, 1)
  assert_equal 0, RLP.compare_length(rlp, 5)

  rlp = RLP.encode []
  assert_equal 0, RLP.compare_length(rlp, 0)
  assert_equal 1, RLP.compare_length(rlp, -1)
  assert_equal (-1), RLP.compare_length(rlp, 1)
end

assert("test_favor_short_string_form") do
  rlp = Utils.decode_hex 'b8056d6f6f7365'
  assert_raise(DecodingError) { RLP.decode(rlp, {}) }

  rlp = Utils.decode_hex '856d6f6f7365'
  assert_equal 'moose', RLP.decode(rlp, {})
end

assert("test_inference") do
  obj_sedes_pairs = [
    [5, Sedes.big_endian_int],
    [0, Sedes.big_endian_int],
    [-1, nil],
    ['', Sedes.binary],
    ['asdf', Sedes.binary],
    ['\xe4\xf6\xfc\xea\xe2\xfb', Sedes.binary],
    [[], Sedes::List.new],
    [[1, 2, 3], Sedes::List.new([Sedes.big_endian_int]*3)],
    [[[], 'asdf'], Sedes::List.new([[], Sedes.binary])],
  ]

  obj_sedes_pairs.each do |obj, sedes|
    if sedes
      inferred = Sedes.infer obj
      # assert_equal sedes, inferred
      assert_equal(inferred.serialize(obj), sedes.serialize(obj))
    else
      assert_raise RLP::TypeError do
        Sedes.infer obj
      end
    end
  end
end

# TODO
# assert("test_bytes_to_str") do
#   assert_equal 'UTF-8', bytes_to_str("abc").encoding.name
# end

# assert("test_str_to_bytes") do
#   assert_equal 'ASCII-8BIT', str_to_bytes("abc").encoding.name
# end

assert("test_big_endian_to_int") do
  int = [1, 100000, 100000000, 2**256-1]
  bytes = ["\x01", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map {|s| s }

  int.zip(bytes).each do |i, b|
    assert_equal i, big_endian_to_int(b)
  end
end

assert("test_int_to_big_endian") do
  int = [1, 100000, 100000000, 2**256-1]
  bytes = ["\x01", "\x01\x86\xa0", "\x05\xf5\xe1\x00", "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"].map {|s| s }

  int.zip(bytes).each do |i, b|
    assert_equal b, int_to_big_endian(i)
  end
end

assert("test_encode_hex") do
  assert_equal "", encode_hex("")
  assert_equal "616263", encode_hex("abc")
end

# TODO
assert("test_decode_hex") do
  assert_equal "", decode_hex("")
  assert_equal "abc", decode_hex("616263")
  # assert_raise(RLP::TypeError) { decode_hex('xxxx') }
  # assert_raise(RLP::TypeError) { decode_hex('\x00\x00') }
end
