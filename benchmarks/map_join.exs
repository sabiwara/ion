range = 1..100
integers = Enum.shuffle(range)
strings = Enum.map(integers, &<<&1::utf8, &1::utf8>>)
charlists = Enum.map(integers, &[&1, &1])

Benchee.run(
  %{
    "Enum.map_intersperse (strings)" => fn -> Enum.map_intersperse(strings, "-", & &1) end,
    "Enum.map_join (strings)" => fn -> Enum.map_join(strings, "-", & &1) end,
    "Ion.map_join (strings)" => fn -> Ion.map_join(strings, "-", & &1) end,
    "Enum.map_intersperse (charlists)" => fn -> Enum.map_intersperse(charlists, "-", & &1) end,
    "Ion.map_join (charlists)" => fn -> Ion.map_join(charlists, "-", & &1) end,
    "Enum.map_intersperse (ints)" => fn -> Enum.map_intersperse(integers, "-", &to_string/1) end,
    "Enum.map_join (ints)" => fn -> Enum.map_join(integers, "-", & &1) end,
    "Ion.map_join (ints)" => fn -> Ion.map_join(integers, "-", & &1) end,
    "Enum.map_join (range)" => fn -> Enum.map_join(range, "-", & &1) end,
    "Ion.map_join (range)" => fn -> Ion.map_join(range, "-", & &1) end,
  },
  time: 2,
  memory_time: 0.5
)
