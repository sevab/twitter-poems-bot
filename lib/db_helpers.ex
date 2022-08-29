defmodule DbHelpers do
  alias Exqlite.Sqlite3

  # Also, skips very long poems
  def get_random_poem!(conn) do
    {:ok, statement} =
      Sqlite3.prepare(
        conn,
        "SELECT * FROM poems WHERE tweeted_at IS NULL AND length(body) < 1400 ORDER BY RANDOM() LIMIT 1"
      )

    get_poem_from_statement!(conn, statement)
  end

  def get_poem_by_external_id(conn, external_id) do
    {:ok, statement} = Sqlite3.prepare(conn, "SELECT * FROM poems WHERE external_id = ?;")
    :ok = Sqlite3.bind(conn, statement, [external_id])
    get_poem_from_statement!(conn, statement)
  end

  def get_poem_from_statement!(conn, statement) do
    {:row, poem} = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
    poem_arr_to_struct(poem)
  end

  def get_author_by_id!(conn, id) do
    {:ok, statement} = Sqlite3.prepare(conn, "SELECT * FROM authors WHERE id = ?")
    :ok = Sqlite3.bind(conn, statement, [id])
    {:row, author} = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
    author_arr_to_struct(author)
  end

  def poem_arr_to_struct(arr) do
    [id, external_id, external_link, title, body, year, tweeted_at, author_id] = arr

    %{
      id: id,
      external_id: external_id,
      external_link: external_link,
      title: title,
      body: body,
      year: year,
      tweeted_at: tweeted_at,
      author_id: author_id
    }
  end

  def author_arr_to_struct(arr) do
    [id, external_id, name] = arr
    %{id: id, external_id: external_id, name: name}
  end

  def insert_author(conn, author) do
    {:ok, statement} =
      Sqlite3.prepare(conn, "INSERT INTO authors (external_id, name) VALUES (?1, ?2)")

    :ok = Sqlite3.bind(conn, statement, author)
    :done = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
  end

  def insert_poem(conn, poem_params) do
    {:ok, statement} =
      Sqlite3.prepare(
        conn,
        "INSERT INTO poems (external_id, external_link, title, body, year, author_id) VALUES (?1, ?2, ?3, ?4, ?5, ?6)"
      )

    :ok = Sqlite3.bind(conn, statement, poem_params)
    :done = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
  end

  def get_author_by_external_id(conn, external_id) do
    {:ok, statement} = Sqlite3.prepare(conn, "SELECT * FROM authors WHERE external_id = ?;")

    :ok = Sqlite3.bind(conn, statement, [external_id])
    {:row, author} = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
    author_arr_to_struct(author)
  end

  def mark_poem_as_tweeted!(conn, poem) do
    {:ok, statement} = Sqlite3.prepare(conn, "UPDATE poems SET tweeted_at = ?1 WHERE id = ?2")
    timestamp = DateTime.now!("Etc/UTC") |> DateTime.to_iso8601()
    :ok = Sqlite3.bind(conn, statement, [timestamp, poem.id])
    :done = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)

    # Record in a separate table as well for added redundancy
    {:ok, statement} =
      Sqlite3.prepare(
        conn,
        "INSERT INTO tweets (tweeted_at, external_poem_id, external_poem_link, poem_id) VALUES (?1, ?2, ?3, ?4)"
      )

    :ok =
      Sqlite3.bind(conn, statement, [timestamp, poem.external_id, poem.external_link, poem.id])

    :done = Sqlite3.step(conn, statement)
    :ok = Sqlite3.release(conn, statement)
  end

  def create_tables!(conn) do
    :ok =
      Sqlite3.execute(
        conn,
        "CREATE TABLE authors (id INTEGER PRIMARY KEY, external_id TEXT, name TEXT)"
      )

    :ok =
      Sqlite3.execute(
        conn,
        "CREATE TABLE poems (id INTEGER PRIMARY KEY, external_id TEXT, external_link TEXT, title TEXT, body TEXT, year TEXT, tweeted_at TEXT, author_id INTEGER, FOREIGN KEY(author_id) REFERENCES authors(id))"
      )

    # Additional redundancy, save history of tweets to a separate table too
    :ok =
      Sqlite3.execute(
        conn,
        "CREATE TABLE tweets (id INTEGER PRIMARY KEY, tweeted_at TEXT, external_poem_id TEXT, external_poem_link TEXT, poem_id INTEGER, FOREIGN KEY(poem_id) REFERENCES poems(id))"
      )
  end

  def drop_tables!(conn) do
    ~w(authors poems tweets)
    |> Enum.each(fn table_name ->
      :ok = Sqlite3.execute(conn, "DROP TABLE IF EXISTS #{table_name};")
    end)
  end
end
