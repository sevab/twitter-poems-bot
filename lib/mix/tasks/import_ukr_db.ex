defmodule Mix.Tasks.ImportUkrDb do
  import DbHelpers
  import ParseHelpers

  use Mix.Task

  def run(_) do
    {:ok, conn} = Exqlite.Sqlite3.open("db/ukr_poems.db")
    DbHelpers.drop_tables!(conn)
    DbHelpers.create_tables!(conn)

    Path.wildcard("./static/ukr_poems/*.txt")
    |> Enum.each(fn file_path ->
      {:ok, body} = File.read(file_path)

      if String.length(body) < 2500 do
        poem_params = parse_poem(body)
        DbHelpers.insert_author_if_not_exists(conn, poem_params[:author_name])
        author = DbHelpers.get_author_by_name!(conn, poem_params[:author_name])
        date = nil_or_str(poem_params[:date] || poem_params[:year])

        poem_params = [
          file_path,
          nil,
          nil_or_str(poem_params[:title]),
          poem_params[:poem],
          date,
          author.id
        ]

        insert_poem(conn, poem_params)
      end
    end)
  end

  def cleanup_poem_body(text) do
    text
    # `global: false`, so only applies to first occurrance (usualy before poem start)
    |> String.replace("* * *", "\n", global: false)
    # Remove redundant new lines
    |> String.replace(~r/\n\n+/, "\n\n")
    # Remove fake titles, e.g.:
    |> String.replace(~r/(«.+…».+)/, "")
    |> String.replace(~r/(«.+..».+)/, "")
    # Trim very long lines:
    |> String.replace(~r/(______)+.+/, "__________")
    # Trim other repetitions (e.g. Багряний Іван: Цукроварня)
    |> String.replace(~r/(. . . . )+.+/, "__________")
    |> String.trim()
  end

  def parse_poem(text) do
    [author_name | poem_body] = text |> String.split("\n")

    author_name = capitalize_name(author_name)

    if Enum.at(poem_body, 1) == "" && Enum.at(poem_body, 2) == "" do
      [title | poem_body] = poem_body
      poem_body = Enum.join(poem_body, "\n")

      return_val =
        title
        |> parse_year_from_title()
        |> cast_fake_title_to_nil()

      poem_body = cleanup_poem_body(poem_body)

      return_val =
        Map.merge(
          %{author_name: author_name, poem: poem_body},
          return_val
        )

      return_val = Map.merge(return_val, parse_date_from_bottom(return_val.poem))
      return_val
    else
      poem_body = Enum.join(poem_body, "\n")
      %{author_name: author_name, title: nil, poem: cleanup_poem_body(poem_body)}
    end
  end

  defp capitalize_name(name) do
    name
    |> String.split(" ")
    |> Enum.map(fn x ->
      String.capitalize(x)
      |> String.split("-")
      |> Enum.map(fn x -> String.capitalize(x) end)
      |> Enum.join("-")
    end)
    |> Enum.join(" ")
  end

  def cast_fake_title_to_nil(map) do
    if map.title |> String.trim() |> String.replace(~r/(«.+…»)/, "") == "" do
      Map.merge(map, %{title: nil})
    else
      if map.title |> String.trim() |> String.replace(~r/(«.+..»)/, "") == "" do
        Map.merge(map, %{title: nil})
      else
        map
      end
    end
  end

  def parse_year_from_title(title) do
    results = Regex.scan(~r/\([[:digit:]]+\)/, title)

    if length(results) == 1 do
      year = Regex.scan(~r/([[:digit:]]+)/, title) |> List.first() |> List.first()
      title = String.replace(title, List.first(List.first(results)), "") |> String.trim()
      %{title: title, year: year}
    else
      results = Regex.scan(~r/\([[:digit:]]+—[[:digit:]]+\)/, title)

      if length(results) == 1 do
        year = Regex.scan(~r/([[:digit:]]+—[[:digit:]]+)/, title) |> List.first() |> List.first()
        title = String.replace(title, List.first(List.first(results)), "") |> String.trim()
        %{title: title, year: year}
      else
        %{title: title}
      end
    end
  end

  def parse_date_from_bottom(text) do
    # E.g. 1911—1918
    results = Regex.scan(~r/\n.+[[:digit:]]+—[[:digit:]]+$/, text)

    if length(results) == 1 do
      date = List.first(List.first(results))
      poem = String.replace(text, date, "") |> String.trim()

      date =
        Regex.scan(~r/[[:digit:]]+—[[:digit:]]+/, date)
        |> List.first()
        |> List.first()
        |> String.trim()

      %{date: date, poem: poem}
    else
      # E.g. "\n1982", "\n13 березня 1935"
      results = Regex.scan(~r/\n.+[[:digit:]]+$/, text)

      if length(results) == 1 do
        date = List.first(List.first(results))
        poem = String.replace(text, date, "") |> String.trim()

        date =
          Regex.scan(~r/.+[[:digit:]]+/, date) |> List.first() |> List.first() |> String.trim()

        %{date: date, poem: poem}
      else
        # E.g. "\n[1892]"
        results = Regex.scan(~r/\n.+[[[:digit:]]]+$/, text)

        if length(results) == 1 do
          date = List.first(List.first(results))
          poem = String.replace(text, date, "") |> String.trim()

          date =
            Regex.scan(~r/[[:digit:]]+/, date) |> List.first() |> List.first() |> String.trim()

          %{date: date, poem: poem}
        else
          %{}
        end
      end
    end
  end
end
