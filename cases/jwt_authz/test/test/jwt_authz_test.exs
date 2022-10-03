defmodule JwtAuthzTest do
  use ExUnit.Case

  alias Support.Logs, as: LogHelpers
  alias Support.EMQTT, as: EMQTTHelpers


  @timeout 60_000

  setup do
    {:ok, r} = Redix.start_link()

    {:ok, _} = LogHelpers.wait_for_log(r, "emqx", ~r/EMQ X Broker .*? is running now/, @timeout)
  end

  test "authorize with JWT (rsa)" do
    assert {:ok, %HTTPoison.Response{body: jwt, status_code: 200}} = HTTPoison.post(
      "http://jwt-server:4001/rs/authn_acl_token",
      "username=subuser&password=pass2",
      [{"Content-Type", "application/x-www-form-urlencoded"}]
    )

    {:ok, client} = EMQTTHelpers.connect(
      username: "subuser",
      password: jwt,
      host: 'emqx',
      port: 1883
    )

    assert {:ok, _, [0]} = :emqtt.subscribe(client, "foo")
    assert {:ok, _, [128]} = :emqtt.subscribe(client, "bar")

    :emqtt.disconnect(client)
  end
end
