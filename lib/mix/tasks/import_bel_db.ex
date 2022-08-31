defmodule Mix.Tasks.ImportBelDb do
  import DbHelpers
  import ParseHelpers

  use Mix.Task

  def run(_) do
    {:ok, conn} = Exqlite.Sqlite3.open("db/bel_poems.db")
    DbHelpers.drop_tables!(conn)
    DbHelpers.create_tables!(conn)

    read_json_from_file("./static/authors.json")
    |> Enum.each(fn author ->
      insert_author(conn, [author["id"], nil_or_str(author["name"])])
    end)

    read_json_from_file("./static/poems.json")
    |> Enum.each(fn poem ->
      author = get_author_by_external_id(conn, poem["authar"])

      poem_params =
        [
          poem["id"],
          poem["link"],
          poem["name"],
          poem["text"],
          poem["year"],
          author.id
        ]
        |> clean_poem_params

      insert_poem(conn, poem_params)
    end)

    tweeted_already = [
      "5FCE578F-DF50-4AC8-BF80-F62162FD72CF",
      "79FC5550-C5E5-414B-A9CD-9299CAFE7744",
      "0EC508BF-2EB4-4B99-8E32-D75A11D1BE4F",
      "63644A89-B596-4ED7-996C-247698C89278",
      "DEA1B0FC-53B9-4228-8379-8BBCFC0B20BC",
      "64BE3E2C-8540-47B9-8EB3-E56590BC6D7E",
      "3A1536C5-883F-4832-94F5-DA98B8437308",
      "7014D972-9AD2-4916-800C-8E45A20E3672",
      "4BDF8D75-0892-4E9C-8139-7FFF5E0C1037"
    ]

    tweeted_already
    |> Enum.each(fn external_id ->
      poem = get_poem_by_external_id(conn, external_id)
      mark_poem_as_tweeted!(conn, poem)
    end)
  end

  defp clean_poem_params(poem_params) do
    [id, link, title, body, year, author_id] = poem_params
    title = nil_or_str(title)
    # Skip BY db poem titles starting with ***
    title = if title && String.starts_with?(title, "**"), do: nil, else: title

    year = nil_or_str(year)

    [id, link, title, body, year, author_id]
  end

  defp read_json_from_file(file_path) do
    with {:ok, body} <- File.read(file_path),
         {:ok, json} <- Jason.decode!(body) do
      {:ok, json}
    end
  end
end
