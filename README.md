# Jibe

An elixir library for comparing an arbitralily nested map/list against a pattern.

This is intended as a helper in unit tests, but there's nothing forcing that to be
the case. It's just a simple set of elixir functions that could be called from anywhere. 

See `jibe.ex` for examples.

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


