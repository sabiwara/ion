defmodule Bench.IO.Empty do
  def inputs() do
    for n <- [5, 50, 500] do
      :rand.seed(:exrop, {1, 2, 3})
      iodata = Stream.repeatedly(fn -> <<?a..?z |> Enum.random()>> end) |> Enum.take(n)
      {"n = #{n}", iodata}
    end ++ [
      {"pathological", Enum.reduce(1..50, "not_empty", fn _, acc -> [acc] end)}
    ]
  end

  def run() do
    Benchee.run(
      [
        {"IO.iodata_length() == 0", fn iodata -> IO.iodata_length(iodata) == 0 end},
        {"Ion.iodata_empty?/1", fn iodata -> Ion.iodata_empty?(iodata) end}
      ],
      inputs: inputs(),
      print: [fast_warning: false]
    )
  end
end

Bench.IO.Empty.run()
