defmodule DiskLogStreamTest do
  use ExUnit.Case

  import DiskLogStream

  @log_name :test_log
  @log_path '/tmp/test_log.bin'

  test "Basic log functions" do
    @log_name = open(@log_name, @log_path)

    sync_log(@log_name, "example term 1")
    sync_log(@log_name, "example term 2")
    sync_log(@log_name, [:a, :b, "term", 1234])

    results =
      create_stream(@log_name, @log_path)
      |> Stream.map(fn lg_entry -> lg_entry end)
      |> Enum.to_list()

    assert results == ["example term 1", "example term 2", [:a, :b, "term", 1234]]

    :ok = sync(@log_name)
    :ok = close(@log_name)
    :ok = File.rm!(to_string(@log_path))
  end
end
