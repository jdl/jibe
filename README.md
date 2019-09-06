# Jibe

An elixir library for comparing an arbitralily nested map/list against a pattern.

This is intended as a helper in unit tests, but there's nothing forcing that to be
the case. It's just a simple set of elixir functions that could be called from anywhere. 
Having said that, I use it in a lot of tests and pretty much only in tests.

## Example

```elixir
pattern = [:red, :green]

# Partial matches are fine.
Jibe.match?(pattern, [:blue, :red, :purple, :green])
true

# Missing elements are no good though.
# In this case :red was expected and not found.
Jibe.match?(pattern, [:green])
false

# Order matters by deault.
Jibe.match?(pattern, [:green, :red])
false

# Or you don't care about order.
Jibe.match?({:unsorted, pattern}, [:green, :red])
true
```

The `pattern` can be an arbitraily nested structure of maps and lists.
See the docs for examples using maps, dates, wildcards, and more.

## What does this look like in a typical unit test?

I made this originally to help test API results in Phoenix apps. If you don't use Phoenix just imagine
that we have a thing that is spewing out JSON, and we'd like to check some or all of our fields. JSON 
deserialization is external to `Jibe`. Use `Poison` or `Jason` or whatever you want.

```elixir

# Again, I'm assuming "Phoenix" here, but Jibe doesn't care.

defmodule MyAppWeb.UsersControllerTest do
  use MyApp.ConnCase
  import MyApp.Factory # using `ex_machina` in this case. 
  
  setup do
    fred = insert(:user, first_name: "Fred", last_name: "Flintstone")
    barney = insert(:user, first_name: "Barney", last_name: "Rubble")
    wilma = insert(:user, first_name: "Wilma", last_name: "Flintstone")
    
    conn =
      build_conn()
      # |> whatever else you need to do to set up your conn (login, etc.)
    
    {:ok, conn: conn, users: [fred, barney, wilma]}
  end

  test "index of all users", %{conn: conn, users: [fred, barney, wilma]} do
    data =
      conn
      |> get(users_path(conn, :index))
      |> json_response(200) # JSON is deserialized into Elixir maps/lists here

    # Usually I'll check the shape of one of the results, and then just look for IDs
    # or something smaller than "the entire record" for the rest. This works because 
    # Jibe assumes that your pattern is a subset of the actual data.
    
    # If I know and expect to enforce a particular sort order.
    pattern =
      [
        %{
          "id" => fred.id,
          "first_name" => "Fred",
          "last_name" => "Flintstone"
        },
        %{ "id" => barney.id },
        %{ "id" => wilma.id }
      ]
    assert Jibe.match?(pattern, data)
    
    # If instead I don't care about the sort order.
    # This is slower to execute, but in a small unit test it barely matters.
    pattern =
      {:unsorted, [
        %{
          "id" => fred.id,
          "first_name" => "Fred",
          "last_name" => "Flintstone"
        },
        %{ "id" => barney.id},
        %{ "id" => wilma.id}
      ]}
    assert Jibe.match?(pattern, data)
  end
```

## Installation

Maybe some day I'll get around to versioning this. For now, you can pull it directly
from github.

The package can be installed by adding `jibe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jibe, git: "https://github.com/jdl/jibe.git"}
  ]
end
```


