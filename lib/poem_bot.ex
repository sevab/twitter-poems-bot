defmodule PoemBot do
  import DbHelpers

  def tweet(db_name: db_name, hashtags: hashtags) do
    {:ok, conn} = Exqlite.Sqlite3.open(db_name)

    poem = get_random_poem!(conn)
    author = get_author_by_id!(conn, poem.author_id)

    prepare_tweet_text(
      poem: poem,
      author: author,
      hashtags: hashtags
    )
    |> split_text_into_threads()
    |> tweet_a_thread()

    mark_poem_as_tweeted!(conn, poem)
  end

  def prepare_tweet_text(poem: poem, author: author, hashtags: hashtags) do
    # Trim leading and trailing whitespaces:
    poem_arr =
      poem.body
      |> String.split("\n")
      |> Enum.map(fn s -> String.trim(s) end)

    poem_arr = if poem.title, do: ["«#{poem.title}»" | poem_arr], else: poem_arr

    poem_arr =
      if author.name do
        author_year_str =
          if poem.year, do: "\n– #{author.name}, #{poem.year}", else: "\n– #{author.name}"

        poem_arr ++ [author_year_str]
      else
        if poem.year, do: poem_arr ++ ["\n#{poem.year}"], else: poem_arr
      end

    poem_arr ++ ["\n\n#{hashtags}"]
  end

  def split_text_into_threads(arr) do
    chunk_fun = fn element, acc ->
      if String.length(Enum.join([element | acc], "\n")) > 280 do
        {:cont, Enum.reverse(acc), [element]}
      else
        {:cont, [element | acc]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    Enum.chunk_while(arr, [], chunk_fun, after_fun)
  end

  def tweet_a_thread(arr) do
    Enum.reduce(arr, 0, fn lines, tweet_id ->
      tweet_body = Enum.join(lines, "\n")

      tweet =
        if tweet_id == 0 do
          ExTwitter.update(tweet_body)
        else
          ExTwitter.update(tweet_body, in_reply_to_status_id: tweet_id)
        end

      tweet.id
    end)

    :ok
  end
end
