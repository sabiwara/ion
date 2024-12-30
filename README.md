# Ion

<img src="https://raw.githubusercontent.com/sabiwara/ion/main/images/logo_large.png" width="80" height="80" align="right" alt="Ion">

[![Hex Version](https://img.shields.io/hexpm/v/ion.svg)](https://hex.pm/packages/ion)
[![docs](https://img.shields.io/badge/docs-hexpm-blue.svg)](https://hexdocs.pm/ion/)
[![CI](https://github.com/sabiwara/ion/workflows/CI/badge.svg)](https://github.com/sabiwara/ion/actions?query=workflow%3ACI)

Lightweight utility library for efficient IO data and chardata handling.

## TLDR

Interpolation:

```elixir
# plain string
"#{name}: #{count}."
# IO data (using Ion)
~i"#{name}: #{count}."
# IO data (manual)
[name, " ", to_string(count), ?.]
```

Joining:

```elixir
# plain string
Enum.join(integers, "+")
# IO data (using Ion)
Ion.join(integers, "+")
# IO data (manual)
Enum.map_intersperse(integers, "+", &to_string/1)
```

Map joining:

```elixir
# plain string
Enum.map_join(users, ", ", fn user -> "#{user.first}.#{user.last}@passione.org" end)
# IO data (using Ion)
Ion.map_join(users, ", ", fn user -> ~i"#{user.first}.#{user.last}@passione.org" end)
# IO data (manual)
Enum.map_intersperse(users, ", ", fn user -> [user.first, ?., user.last, "@passione.org"] end)
```

## Why `Ion`?

[IO data and chardata](https://hexdocs.pm/elixir/io-and-the-file-system.html#iodata-and-chardata)
are one of the secret weapons behind Elixir and Erlang performance when it comes
to string processing and IO. Turns out the fastest way to concatenate strings
is: avoiding concatenation in the first place!

While it is perfectly possible to handcraft IO data with just the standard
library, it can sometimes be tedious, cryptic and error prone. `Ion` provides a
few common recipes which:

- are drop-in replacements, with APIs consistent with the standard way of
  building strings
- reduce the cognitive overhead and make the intent explicit
- are implemented in an optimal fashion (`Ion` is fast!)
- help reducing bugs through better typing (see below)

The examples above illustrate how easy it is to migrate from building strings to
building IO data or chardata.

### Increased safety

Building IO lists manually or through interspersing is error prone: we need to
be careful to cast things that are neither strings nor nested IO data or will
end up with invalid data:

```elixir
iex> as_bytes = Enum.intersperse(100..105, "+")
[100, "+", 101, "+", 102, "+", 103, "+", 104, "+", 105]
iex> IO.iodata_to_binary(as_bytes)
"d+e+f+g+h+i"
# need to make sure we have strings:
iex> Enum.map_intersperse(100..105, "+", &to_string/1) |> IO.iodata_to_binary()
# works just like Enum.join/2:
iex> Ion.join(100..105, "+") |> IO.iodata_to_binary()
"100+101+102+103+104+105"
```

### Performance

Because they are specialized, the join functions should also be faster than
interspersing (~1.5x, see the `benchmarks` folder).

## Installation

Ion can be installed by adding `Ion` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ion, "~> 0.1.0"}
  ]
end
```

Or you can just try it out from `iex` or an `.exs` script:

```elixir
iex> Mix.install([:ion])
:ok
iex> Ion.join(["Hello", :world], ",")
["Hello", ",", "world"]
```

Documentation can be found at [https://hexdocs.pm/ion](https://hexdocs.pm/ion).

## FAQ

### How to silence dialyzer warnings?

Unfortunately, dialyzer [might warn](https://github.com/erlang/otp/issues/5937) about the use improper lists, which is intentional when building IO data:

```
List construction (cons) will produce an improper list, because its second argument is binary().
```

To disable these warnings:

```elixir
# in the whole module
@dialyzer :no_improper_lists

# specifying function/arity pairs returning IO-data:
@dialyzer {:no_improper_lists, [my_fun: 2, another_one: 1]}
```

## Copyright and License

Ion is licensed under the [MIT License](LICENSE.md).
