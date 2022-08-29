defmodule Mix.Tasks.ResetDb do
  import DbHelpers

  use Mix.Task

  def run(_) do
    {:ok, conn} = Exqlite.Sqlite3.open("db/poems.db")
    drop_tables!(conn)
  end
end
