defmodule Ion do
  @moduledoc ~S"""
  Lightweight utility library for efficient IO data and chardata handling.

  ## Why `Ion`?

  See [`README`](./README.md).

  ## Examples

  [IO data and chardata](https://hexdocs.pm/elixir/io-and-the-file-system.html#iodata-and-chardata)
  can be easily be built using:

  a. interpolation with the [`~i` sigil](`Ion.sigil_i/2`):

        iex> import Ion, only: :sigils
        iex> ~i"atom: #{:foo}, number: #{12 + 2.35}\n"
        ["atom: ", "foo", ", number: ", "14.35", 10]

  b. joining using `join/2` or `map_join/3`:

        iex> Ion.join(100..103, ",")
        [[["100", "," | "101"], "," | "102"], "," | "103"]

        iex> Ion.map_join(1..4, ",", & &1 + 100)
        [[["101", "," | "102"], "," | "103"], "," | "104"]

  """

  @doc ~S"""
  A sigil to build [IO data](https://hexdocs.pm/elixir/IO.html#module-io-data) or chardata and
  avoid string concatenation.

  Use `import Ion` to use it, or `import Ion, only: :sigils`.

  This sigil provides a faster version of string interpolation which:
  - will build a list with all chunks instead of concatenating them as a string
  - will keep interpolated lists and binaries untouched, without any validation or transformation
  - will cast anything else using `to_string/1`

  Works with both [IO data](https://hexdocs.pm/elixir/IO.html#module-io-data) and
  [Chardata](https://hexdocs.pm/elixir/IO.html?#module-chardata).
  See their respective documentation or this
  [guide](https://hexdocs.pm/elixir/io-and-the-file-system.html#iodata-and-chardata)
  for more information.

  ## Examples

      iex> ~i"atom: #{:foo}, number: #{12 + 2.35}\n"
      ["atom: ", "foo", ", number: ", "14.35", 10]

  The data produced corresponds to the binary that a regular string interpolation
  would have produced:

      iex> IO.iodata_to_binary(~i"atom: #{:foo}, number: #{12 + 2.35}\n")
      "atom: foo, number: 14.35\n"
      iex> "atom: #{:foo}, number: #{12 + 2.35}\n"
      "atom: foo, number: 14.35\n"

  Can be used to build chardata too:

      iex> chardata = ~i"charlist: #{~c(ジョルノ)}!"
      ["charlist: ", [12472, 12519, 12523, 12494], 33]
      iex> IO.chardata_to_string(chardata)
      "charlist: ジョルノ!"

  """
  defmacro sigil_i(term, modifiers)

  defmacro sigil_i({:<<>>, _line, pieces}, []), do: sigil_i_pieces(pieces)

  defp sigil_i_pieces([]), do: []
  defp sigil_i_pieces(["" | pieces]), do: sigil_i_pieces(pieces)
  defp sigil_i_pieces([piece]), do: sigil_i_piece(piece, :last)

  defp sigil_i_pieces([piece, last]) do
    quote do
      [unquote(sigil_i_piece(piece)) | unquote(sigil_i_piece(last, :last))]
    end
  end

  defp sigil_i_pieces([piece | pieces]) do
    [sigil_i_piece(piece, :not_last) | sigil_i_pieces(pieces)]
  end

  defp sigil_i_piece(piece, ctx \\ nil)

  defp sigil_i_piece({:"::", _, [{{:., _, _}, _, [expr]}, {:binary, _, _}]}, _) do
    quote generated: true do
      case unquote(expr) do
        # TODO extra safety: check head to prevent list of garbage
        data when is_binary(data) -> data
        [] -> []
        # for extra safety, shallow check to prevent lists of the wrong type
        [h | _] = data when is_list(h) or is_binary(h) or is_integer(h) -> data
        data when not is_list(data) -> String.Chars.to_string(data)
      end
    end
  end

  defp sigil_i_piece(piece, ctx) when is_binary(piece) do
    case Macro.unescape_string(piece) do
      <<char>> when char < 128 and ctx == :last -> [char]
      <<char>> when char < 128 -> char
      binary -> binary
    end
  end

  @doc """
  Joins the given `enumerable` into IO data or chardata using `joiner` as separator.

  It is a fast equivalent to `Enum.join/2`.

  ## Examples

      iex> iodata = Ion.join(1..3)
      iex> IO.iodata_to_binary(iodata)
      "123"

      iex> iodata = Ion.join(1..3, " + ")
      iex> IO.iodata_to_binary(iodata)
      "1 + 2 + 3"

  """
  @spec join(Enumerable.t(data | String.Chars.t()), binary()) :: data
        when data: iodata() | IO.chardata()
  def join(enumerable, joiner \\ "") when is_binary(joiner) do
    case joiner do
      "" when is_list(enumerable) -> join_list(enumerable, [])
      "" -> Enum.reduce(enumerable, [], &[&2 | ~i"#{&1}"])
      _ when is_list(enumerable) -> join_list(enumerable, joiner, nil)
      _ -> join_enumerable(enumerable, joiner)
    end
  end

  @compile {:inline, join_list: 2}

  defp join_list([], acc), do: acc

  defp join_list([head | tail], acc) do
    join_list(tail, append_to_acc(head, acc))
  end

  @compile {:inline, join_list: 3}

  defp join_list([], _joiner, acc), do: acc || []

  defp join_list([head | tail], joiner, acc) do
    join_list(tail, joiner, append_to_optional_acc(head, acc, joiner))
  end

  defp join_enumerable(enumerable, joiner) do
    Enum.reduce(enumerable, nil, &append_to_optional_acc(&1, &2, joiner)) || []
  end

  @doc """
  Maps and joins the given `enumerable` as IO data or chardata, in one pass.

  It is a fast equivalent to `Enum.map_join/3`.

  ## Examples

      iex> iodata = Ion.map_join(1..3, &(&1 * 2))
      iex> IO.iodata_to_binary(iodata)
      "246"

      iex> iodata = Ion.map_join(1..3, " + ", &(&1 * 2))
      iex> IO.iodata_to_binary(iodata)
      "2 + 4 + 6"

  """
  @spec map_join(Enumerable.t(element), binary(), (element -> data | String.Chars.t())) :: data
        when data: iodata() | IO.chardata(), element: term()
  def map_join(enumerable, joiner \\ "", mapper)
      when is_binary(joiner) and is_function(mapper, 1) do
    case joiner do
      "" when is_list(enumerable) -> map_join_list(enumerable, mapper, [])
      "" -> Enum.reduce(enumerable, [], &append_to_acc(mapper.(&1), &2))
      _ when is_list(enumerable) -> map_join_list(enumerable, joiner, mapper, nil)
      _ -> map_join_enumerable(enumerable, joiner, mapper)
    end
  end

  @compile {:inline, map_join_list: 3}

  defp map_join_list([], _mapper, acc), do: acc

  defp map_join_list([head | tail], mapper, acc) do
    map_join_list(tail, mapper, append_to_acc(mapper.(head), acc))
  end

  @compile {:inline, map_join_list: 4}

  defp map_join_list([], _joiner, _mapper, acc), do: acc || []

  defp map_join_list([head | tail], joiner, mapper, acc) do
    acc = mapper.(head) |> append_to_optional_acc(acc, joiner)
    map_join_list(tail, joiner, mapper, acc)
  end

  defp map_join_enumerable(enumerable, joiner, mapper) do
    Enum.reduce(enumerable, nil, &append_to_optional_acc(mapper.(&1), &2, joiner)) || []
  end

  @compile {:inline, append_to_acc: 2}

  defp append_to_acc(raw, acc) do
    data = ~i"#{raw}"

    case acc do
      [] -> data
      _ -> [acc | data]
    end
  end

  @compile {:inline, append_to_optional_acc: 3}

  defp append_to_optional_acc(raw, acc, joiner) do
    data = ~i"#{raw}"

    case acc do
      nil -> data
      _ -> [acc, joiner | data]
    end
  end

  @doc ~S"""
  Returns `true` if `iodata_or_chardata` is empty.

  Unlike `IO.iodata_length(iodata) == 0` which needs to walk the complete tree,
  it will bail early as soon as it finds at least one byte or codepoint.

  It should be constant time for most typical outputs, with the exception of
  atypical cases where the head is a deep nested tree.

  Even if `IO.iodata_length/1` is a very efficient BIF implemented in C, it has a linear
  algorithmic complexity and can become slow on bigger trees.

  ## Examples

      iex> Ion.iodata_empty?(["", []])
      true
      iex> Ion.iodata_empty?(~c"a")
      false
      iex> Ion.iodata_empty?(["a"])
      false
      iex> Ion.iodata_empty?(["", [], ["" | "c"]])
      false

  """
  @spec iodata_empty?(iodata() | IO.chardata()) :: boolean()
  def iodata_empty?(iodata_or_chardata)

  def iodata_empty?(binary) when is_binary(binary), do: binary === ""
  def iodata_empty?([]), do: true
  def iodata_empty?([head | _]) when is_integer(head), do: false

  def iodata_empty?([head | rest]) do
    # optimized `and`
    case iodata_empty?(head) do
      false -> false
      _ -> iodata_empty?(rest)
    end
  end
end
