# DiskLogStream

**DiskLogStream can create streams from disklog logs**
**Is helpfull if you want to iterate over WAL, or audit trails**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `disk_log_stream` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:disk_log_stream, "~> 0.1.0"}
  ]
end
```

## How to use it

```elixir

 import DiskLogStream

 log_name = :test_log
 log_path = '/tmp/test_log.bin'

 # open the a log, the name is atom, the path charlist.
 log_name = open(log_name, log_path)

 # log some terms, binaries etc.. pretty much everything that can be converted with term_to_binary
 sync_log(log_name, "example term 1")
 sync_log(log_name, "example term 2")
 sync_log(log_name, [:a, :b, "term", 1234])

 iex(11)>  create_stream(log_name, log_path)  |> Stream.map(fn lg_entry -> lg_entry end)  |> Enum.to_list()
 ["example term 1", "example term 2", [:a, :b, "term", 1234]]


```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/disk_log_stream](https://hexdocs.pm/disk_log_stream).
