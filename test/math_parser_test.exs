defmodule AbacusTest do
  use ExUnit.Case
  doctest Abacus

  test "the lexer" do
    assert [
             {:number, _, 1},
             {:+, _},
             {:number, _, 1}
           ] = lex_term("1+1")

    assert [
             {:"(", _},
             {:number, _, 3.2},
             {:+, _},
             {:number, _, 4},
             {:")", _}
           ] = lex_term("(3.2 + 4)")
  end

  describe "parse" do
    test "basic operators" do
      assert {:add, 1, 3} = parse_term("1+3")
      assert {:subtract, 50, 10} = parse_term("50- 10")
    end

    test "precedence and association" do
      assert {:add, {:add, 1, 1}, 1.2} = parse_term("1 + 1 + 1.2")

      assert {:add, {:add, 1, {:power, 3, 1}}, 1} = parse_term("1 + 3 ^ 1 + 1")

      assert {:add, {:multiply, 1, 2}, {:multiply, 3, 2}} = parse_term("1*2 + 3*2")
    end

    test "parantheses" do
      assert {:add, 1, {:add, 1, 3}} = parse_term("1 + (1 + 3)")

      assert {:add, 1, 1} = parse_term("((((((((((((((((1)))))))))))))))) + 1")
    end

    test "functions" do
      assert {:function, "sin", [90]} = parse_term("sin(90)")

      assert {:function, "max", [1, 3]} = parse_term("max(1, 3)")

      assert {:function, "cos", [{:multiply, 45, 2}]} = parse_term("cos(45 * 2)")
    end

    test "variable access" do
      assert {:access, [variable: "a"]} = parse_term("a")

      assert {:access, [variable: "a", index: 2]} = parse_term("a[2]")

      assert {:access, [variable: "a", variable: "b", index: {:add, 1, 2}]} =
               parse_term("a.b[1+2]")
    end

    test "bitwise operators" do
      assert {:not, 10} = parse_term("~10")
      assert {:and, 1, 2} = parse_term("1 & 2")
      assert {:or, 2, 3} = parse_term("2 | 3")
      assert {:xor, 3, 4} = parse_term("3 |^ 4")
      assert {:shift_left, 1, 8} = parse_term("1 << 8")
      assert {:shift_right, 32, 2} = parse_term("32 >> 2")
    end

    test "ternary operator" do
      assert {:ternary_if, {:neq, {:access, [variable: "battery"]}, 0},
              {:divide, {:subtract, {:access, [variable: "battery"]}, 1}, 253},
              nil} = parse_term("battery != 0 ? (battery - 1) / 253 : null")
    end
  end

  def parse_term(string) do
    {:ok, result} =
      string
      |> lex_term
      |> :math_term_parser.parse()

    result
  end

  def lex_term(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> lex_term
  end

  def lex_term(string) do
    {:ok, tokens, _} = :math_term.string(string)
    tokens
  end
end
