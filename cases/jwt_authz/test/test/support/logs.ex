defmodule Support.Logs do
  @interval 100

  @key "filebeat"

  def wait_for_log(redix, host, pattern, timeout) do
    deadline = timeout + :erlang.monotonic_time(:millisecond)
    wait_for_log_till(redix, host, pattern, deadline)
  end

  defp wait_for_log_till(redix, host, pattern, deadline) do
    if :erlang.monotonic_time(:millisecond) > deadline do
      :timeout
    else
      case get_logs(redix, host, pattern) do
        [log | _] -> {:ok, log}
        [] ->
          :timer.sleep(@interval)
          wait_for_log_till(redix, host, pattern, deadline)
      end
    end
  end

  def get_logs(redix, host, pattern) do
    redix
    |> Redix.command!(["LRANGE", @key, "0", "-1"])
    |> Enum.map(& Jason.decode!(&1))
    |> Enum.filter(
      fn
        %{"host" => %{"name" => ^host}} -> true;
        %{} -> false
      end
    )
    |> Enum.filter(fn %{"message" => message} -> message =~ pattern end)
  end

end
