range = 1..100
integers = Enum.shuffle(range)
strings = Enum.map(integers, &<<&1::utf8, &1::utf8>>)
charlists = Enum.map(integers, &[&1, &1])

Benchee.run(
  %{
    "Enum.intersperse (strings)" => fn -> Enum.intersperse(strings, "-") end,
    "Enum.join (strings)" => fn -> Enum.join(strings, "-") end,
    "Ion.join (strings)" => fn -> Ion.join(strings, "-") end,
    "Enum.intersperse (charlists)" => fn -> Enum.intersperse(charlists, "-") end,
    "Ion.join (charlists)" => fn -> Ion.join(charlists, "-") end,
    "Enum.map_intersperse (ints)" => fn -> Enum.map_intersperse(integers, "-", &to_string/1) end,
    "Enum.join (ints)" => fn -> Enum.join(integers, "-") end,
    "Ion.join (ints)" => fn -> Ion.join(integers, "-") end,
    "Enum.join (range)" => fn -> Enum.join(range, "-") end,
    "Ion.join (range)" => fn -> Ion.join(range, "-") end,
  },
  time: 2,
  memory_time: 0.5
)
