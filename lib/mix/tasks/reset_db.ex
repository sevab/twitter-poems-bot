defmodule Mix.Tasks.ResetDb do
  import DbHelpers

  use Mix.Task

  # `mix reset_db db/ukr_poems.db`
  def run([db_name]) do
    {:ok, conn} = Exqlite.Sqlite3.open(db_name)
    drop_tables!(conn)
  end
end
