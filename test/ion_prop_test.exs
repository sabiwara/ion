defmodule Ion.PropTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Ion, only: :sigils

  @moduletag timeout: :infinity
  @moduletag :property

  describe "~i sigil" do
    property "keep iodata untouched" do
      check all(data <- iodata()) do
        assert ~i"#{data}" == data
        assert ~i"#{data}?" == [data, ??]
        assert ~i"#{data} & co" == [data | " & co"]
        assert ~i"#{data}#{~c[ & co]}" == [data] ++ ~c" & co"

        assert ~i"""
               #{data} & co
               """ == [data | " & co\n"]

        assert ~i"#{data}#{data}" == [data | data]
      end
    end

    property "keep chardata untouched" do
      check all(data <- chardata()) do
        assert ~i"#{data}" == data
        assert ~i"#{data}?" == [data, ??]
        assert ~i"#{data} & co" == [data | " & co"]
        assert ~i"#{data}#{~c[ & co]}" == [data] ++ ~c" & co"

        assert ~i"""
               #{data} & co
               """ == [data | " & co\n"]

        assert ~i"#{data}#{data}" == [data | data]
      end
    end

    property "is consistent for iodata substitutions" do
      check all(sub <- iodata()) do
        assert IO.iodata_to_binary(~i"hi #{sub}") == "hi " <> IO.iodata_to_binary(sub)
        assert IO.iodata_to_binary(~i"#{sub}!") == IO.iodata_to_binary(sub) <> "!"
        assert IO.iodata_to_binary(~i"[#{sub}]") == "[" <> IO.iodata_to_binary(sub) <> "]"
        assert IO.iodata_to_binary(~i"hi #{sub}!\n") == "hi " <> IO.iodata_to_binary(sub) <> "!\n"
        assert IO.iodata_to_binary(~i"✨#{sub}👍🏽") == "✨" <> IO.iodata_to_binary(sub) <> "👍🏽"
      end
    end

    property "is consistent for chardata substitutions" do
      check all(sub <- chardata()) do
        assert IO.chardata_to_string(~i"hi #{sub}") == "hi " <> IO.chardata_to_string(sub)
        assert IO.chardata_to_string(~i"#{sub}!") == IO.chardata_to_string(sub) <> "!"
        assert IO.chardata_to_string(~i"[#{sub}]") == "[" <> IO.chardata_to_string(sub) <> "]"

        assert IO.chardata_to_string(~i"hi #{sub}!\n") ==
                 "hi " <> IO.chardata_to_string(sub) <> "!\n"

        assert IO.chardata_to_string(~i"✨#{sub}👍🏽") == "✨" <> IO.chardata_to_string(sub) <> "👍🏽"
      end
    end

    property "is consistent for String.Chars substitutions (as iodata)" do
      check all(sub <- string_chars()) do
        assert ~i"#{sub}" == to_string(sub)
        assert IO.iodata_to_binary(~i"hi #{sub}") == "hi " <> to_string(sub)
        assert IO.iodata_to_binary(~i"#{sub}!") == to_string(sub) <> "!"
        assert IO.iodata_to_binary(~i"[#{sub}]") == "[" <> to_string(sub) <> "]"
        assert IO.iodata_to_binary(~i"hi #{sub}!\n") == "hi " <> to_string(sub) <> "!\n"
        assert IO.iodata_to_binary(~i"✨#{sub}👍🏽") == "✨" <> to_string(sub) <> "👍🏽"
      end
    end
  end

  property "is consistent for String.Chars substitutions (as chardata)" do
    check all(sub <- string_chars()) do
      assert ~i"#{sub}" == to_string(sub)
      assert IO.chardata_to_string(~i"hi #{sub}") == "hi " <> to_string(sub)
      assert IO.chardata_to_string(~i"#{sub}!") == to_string(sub) <> "!"
      assert IO.chardata_to_string(~i"[#{sub}]") == "[" <> to_string(sub) <> "]"
      assert IO.chardata_to_string(~i"hi #{sub}!\n") == "hi " <> to_string(sub) <> "!\n"
      assert IO.iodata_to_binary(~i"✨#{sub}👍🏽") == "✨" <> to_string(sub) <> "👍🏽"
    end
  end

  property "is consistent with ~s as iodata" do
    check all(binary <- string(:printable), data <- iodata()) do
      assert apply_sigil("i", binary, data) |> IO.iodata_to_binary() ==
               apply_sigil("s", binary, IO.iodata_to_binary(data))
    end
  end

  property "is consistent with ~s as chardata" do
    check all(binary <- string(:printable), data <- chardata()) do
      assert apply_sigil("i", binary, data) |> IO.chardata_to_string() ==
               apply_sigil("s", binary, IO.chardata_to_string(data))
    end
  end

  describe "join/2" do
    property "is consistent with Enum for iodata" do
      check all(list <- list_of(one_of([string_chars(), iodata()])), joiner <- joiner()) do
        stream = Stream.map(list, & &1)

        expected =
          Enum.map_join(list, joiner, fn
            x when is_list(x) -> IO.iodata_to_binary(x)
            x -> x
          end)

        assert Ion.join(list, joiner) |> IO.iodata_to_binary() == expected
        assert Ion.join(stream, joiner) |> IO.iodata_to_binary() == expected
      end
    end

    property "is consistent with Enum for chardata" do
      check all(list <- list_of(one_of([string_chars(), chardata()])), joiner <- joiner()) do
        stream = Stream.map(list, & &1)
        expected = Enum.join(list, joiner)

        assert Ion.join(list, joiner) |> IO.chardata_to_string() == expected
        assert Ion.join(stream, joiner) |> IO.chardata_to_string() == expected
      end
    end
  end

  describe "map_join/3" do
    property "is consistent with Enum for iodata" do
      check all(list <- list_of(one_of([string_chars(), iodata()])), joiner <- joiner()) do
        stream = Stream.map(list, & &1)

        fun = &remove_third_of_values/1

        expected =
          Enum.map_join(list, joiner, fn value ->
            case remove_third_of_values(value) do
              x when is_list(x) -> IO.iodata_to_binary(x)
              x -> x
            end
          end)

        assert Ion.map_join(list, joiner, fun) |> IO.iodata_to_binary() == expected
        assert Ion.map_join(stream, joiner, fun) |> IO.iodata_to_binary() == expected
      end
    end

    property "is consistent with Enum for chardata" do
      check all(list <- list_of(one_of([string_chars(), chardata()])), joiner <- joiner()) do
        stream = Stream.map(list, & &1)

        fun = &remove_third_of_values/1

        expected = Enum.map_join(list, joiner, fun)

        assert Ion.map_join(list, joiner, fun) |> IO.chardata_to_string() == expected
        assert Ion.map_join(stream, joiner, fun) |> IO.chardata_to_string() == expected
      end
    end

    defp remove_third_of_values(term) do
      case :erlang.phash2(term, 3) do
        0 -> []
        _ -> term
      end
    end
  end

  defp string_chars, do: one_of([integer(), atom(:alphanumeric), string(:utf8)])

  defp apply_sigil(<<sigil>>, string, sub) do
    "\"" <> inspected = inspect(string)
    code = <<"~", sigil, ~S("#{sub}), inspected::binary>>
    {result, _} = Code.eval_string(code, [sub: sub], __ENV__)
    result
  end

  defp joiner do
    string(:utf8) |> scale_with_exponent(0.6)
  end

  defp scale_with_exponent(data, exponent) do
    scale(data, fn size -> trunc(:math.pow(size, exponent)) end)
  end
end
