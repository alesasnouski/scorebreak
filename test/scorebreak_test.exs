defmodule ScoreBreakTest do
  use ExUnit.Case

  test "connects to postgres and executes select 1" do
    {:ok, pid} =
      Postgrex.start_link(
        hostname: "localhost",
        port: 5432,
        username: "postgres",
        password: "postgres",
        database: "scorebreak_dev"
      )

    result = Postgrex.query!(pid, "SELECT 1", [])

    assert result.num_rows == 1
    assert result.rows == [[1]]
    GenServer.stop(pid)
  end
end
