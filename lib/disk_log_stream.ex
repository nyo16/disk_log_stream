defmodule DiskLogStream do
  @moduledoc """
  DiskLog Stream is a helper to stream a disklog log using elixir's stream module
  Erlangs api can be find here https://erlang.org/doc/man/disk_log.html#alog-2
  """

  alias :disk_log, as: DiskLog

  @doc """
  Open a log with default settings
  TODO: add extra options to pass through
  """
  @spec open(atom, maybe_improper_list) :: atom
  def open(log_name, path) when is_atom(log_name) and is_list(path) do
    case DiskLog.open(name: log_name, file: path) do
      {:ok, ^log_name} -> log_name
      {:error, {:name_already_open, ^log_name}} -> log_name
      {:repaired, ^log_name, {:recovered, _}, {:badbytes, 0}} -> log_name
      _ -> {:error, "something went wrong trying to open the log"}
    end
  end

  @doc """
  Async log a term to an open disklog log
  You will have to call the "sync" function to sync with disk
  """
  @spec async_log(atom, any) :: :ok | {:error, :no_such_log}
  def async_log(log_name, term) when is_atom(log_name) do
    DiskLog.alog(log_name, term)
  end

  @doc """
  Returns the info of an open log or error
  """
  @spec info(atom) :: keyword | {:error, :no_such_log}
  def info(log_name) when is_atom(log_name), do: DiskLog.info(log_name)

  @spec sync_log(atom, any) ::
          :ok
          | {:error,
             :no_such_log
             | :nonode
             | {:blocked_log, any}
             | {:format_external, any}
             | {:full, any}
             | {:invalid_header, any}
             | {:read_only_mode, any}
             | {:file_error, charlist, any}}
  def sync_log(log_name, term) when is_atom(log_name) do
    DiskLog.log(log_name, term)
  end

  @doc """
  Syncs the in-memory terms to disk
  """
  @spec sync(atom) ::
          :ok
          | {:error,
             :no_such_log
             | :nonode
             | {:blocked_log, any}
             | {:read_only_mode, any}
             | {:file_error, charlist, any}}
  def sync(log_name) when is_atom(log_name), do: DiskLog.sync(log_name)

  @spec close(atom) :: :ok | {:error, :no_such_log | :nonode | {:file_error, charlist, any}}
  def close(log_name) when is_atom(log_name) do
    DiskLog.close(log_name)
  end

  @spec create_stream(atom, maybe_improper_list, any) ::
          ({:cont, any} | {:halt, any} | {:suspend, any}, any ->
             {:halted, any} | {:suspended, any, (any -> any)})
  @doc """
  Create a new stream to read the results in chunks of 64kbytes.

  DiskLogStream.create_stream(:testlog, '/tmp/testlog1.txt')
    |> Stream.map(fn log_entry -> IO.inspect(log_entry) end)
    |> Stream.run

  """
  @spec create_stream(atom, maybe_improper_list) ::
          ({:cont, any} | {:halt, any} | {:suspend, any}, any ->
             {:halted, any} | {:suspended, any, (any -> any)})
  def create_stream(log_name, path, close_log \\ false)
      when is_atom(log_name) and is_list(path) do
    Stream.resource(
      fn ->
        open(log_name, path)
      end,
      &iterate/1,
      fn _ ->
        case close_log do
          true -> DiskLog.close(log_name)
          _ -> :ok
        end
      end
    )
  end

  @spec create_stream(any) :: {:error, <<_::208>>}
  def create_stream(_), do: {:error, "log name should be an atom"}

  defp iterate(log) when is_atom(log) do
    case DiskLog.chunk(log, :start) do
      :eof -> {:halt, []}
      {continuation, results} -> {results, {continuation, log}}
    end
  end

  defp iterate({maybe_next, log}) when is_atom(log) do
    case DiskLog.chunk(log, maybe_next) do
      :eof -> {:halt, []}
      {maybe_next, results} -> {results, {maybe_next, log}}
    end
  end
end
