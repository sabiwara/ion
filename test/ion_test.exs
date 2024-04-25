defmodule IonTest do
  use ExUnit.Case, async: true
  doctest Ion, import: true

  import Ion, only: :sigils

  describe "~i sigil" do
    test "constants" do
      assert ~i"" == []
      assert ~i"?" == [??]
      assert ~i"abc" == "abc"
      assert ~i"é" == "é"
      assert ~i"あ" == "あ"
      assert ~i"おはよう" == "おはよう"

      assert ~i"""
             Hello
             world
             """ == "Hello\nworld\n"
    end

    test "literals" do
      assert ~i"#{"abc"} & co" == ["abc" | " & co"]
      assert ~i"#{~c"abc"} & co" == [~c"abc" | " & co"]
      assert ~i"#{"abc"}!" == ["abc", ?!]

      assert ~i"""
             Hello
             #{"world"}
             """ == ["Hello\n", "world", ?\n]
    end

    test "string variables" do
      string = "abc"
      assert ~i"#{string} & co" == ["abc" | " & co"]
      assert ~i"#{string}!" == ["abc", ?!]
      assert ~i"#{string},#{string}" == ["abc", ?, | "abc"]
      assert ~i"#{string}é" == ["abc" | "é"]
      assert ~i"#{string}あ" == ["abc" | "あ"]

      assert ~i"""
             Hello
             #{string}
             """ == ["Hello\n", "abc", ?\n]
    end

    test "concatenation" do
      x = 1
      y = 2

      assert ~i"#{x}#{y}" == ["1" | "2"]

      assert ~i"""
             #{x}#{y}
             """ == ["1", "2", ?\n]
    end

    test "error on shallow invalid lists" do
      assert_raise CaseClauseError, fn -> ~i"#{[nil]}" end
      assert_raise CaseClauseError, fn -> ~i"[#{[nil]}]" end
    end

    test "modifiers are not allowed" do
      assert_raise FunctionClauseError, fn -> Code.eval_quoted(quote do: ~i""x) end
      assert_raise FunctionClauseError, fn -> Code.eval_quoted(quote do: ~i"a"y) end
      assert_raise FunctionClauseError, fn -> Code.eval_quoted(quote do: ~i"#{1}"z) end
    end
  end
end
