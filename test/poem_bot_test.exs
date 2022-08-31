defmodule PoemBotTest do
  use ExUnit.Case
  doctest PoemBot

  # Longer poem
  defp poem_1 do
    %{
      author_id: 1,
      body:
        "У цёмнай-цёмнай пушчы,\n        На цяглай-цяглай туі,\nСтары-стары крумкач там\nДаўно-даўно гняздуе.\n\nДа крумкача ўсе птушкі\nЛятуць з-за небакраю\nДаведацца, які лёс\nІх у жыцьці чакае.\n\nДы толькі раз у сто год\nЁн зыркачы расплюшчыць\nНа сьвет шырокі глянуць,\nПадаць свой голас пушчы.\n\nI зноўку ціха-ціха.\nУсе-усе чакаюць,\nКалі-калі крумкач той\nШто збаіць ім, што збаіць.",
      external_id: "382F3098-F3CB-4237-B6E7-8DCC880C7B06",
      external_link: "http://rv-blr.com/verse/show/88246",
      id: 9776,
      title: "У цёмнай-цёмнай пушчы",
      tweeted_at: nil,
      year: "1967"
    }
  end

  # Short poem
  defp poem_2 do
    %{
      author_id: 1,
      body:
        "Восень расьпісала\nЛісьце клёнаў барвай.\nПрысадамі блукаюць\nЛетуценьні-мары...\nУ стройнае бярозкі,\nБы сівізна на скронях,\nЖоўтыя лісточкі\nЛяцяць долу... Шолах...",
      external_id: "0E98B6D4-DABB-42CF-84DD-AAEFD8290263",
      external_link: "http://rv-blr.com/verse/show/67263",
      id: 7537,
      title: nil,
      tweeted_at: nil,
      year: nil
    }
  end

  defp author_1 do
    %{external_id: "49", id: 1, name: "Максім Танк"}
  end

  defp author_2 do
    %{external_id: "1423", id: 1, name: "Юрась Півуноў"}
  end

  describe "prepare_poem_text/3" do
    test "renders when all attributes present (also tests that removes whitespace in body)" do
      poem = poem_1()
      author = author_1()

      assert PoemBot.prepare_poem_text(poem: poem, author: author, hashtags: "#УкрТві #БелТві") ==
               [
                 "«У цёмнай-цёмнай пушчы»",
                 "У цёмнай-цёмнай пушчы,",
                 "На цяглай-цяглай туі,",
                 "Стары-стары крумкач там",
                 "Даўно-даўно гняздуе.",
                 "",
                 "Да крумкача ўсе птушкі",
                 "Лятуць з-за небакраю",
                 "Даведацца, які лёс",
                 "Іх у жыцьці чакае.",
                 "",
                 "Ды толькі раз у сто год",
                 "Ён зыркачы расплюшчыць",
                 "На сьвет шырокі глянуць,",
                 "Падаць свой голас пушчы.",
                 "",
                 "I зноўку ціха-ціха.",
                 "Усе-усе чакаюць,",
                 "Калі-калі крумкач той",
                 "Што збаіць ім, што збаіць.",
                 "\n",
                 "Максім Танк",
                 "1967",
                 "\n#УкрТві #БелТві"
               ]
    end

    test "skips title and year if doesn't exist" do
      poem = poem_1() |> Map.put(:title, nil) |> Map.put(:year, nil)
      author = author_1()

      assert PoemBot.prepare_poem_text(poem: poem, author: author, hashtags: "#УкрТві #БелТві") ==
               [
                 "У цёмнай-цёмнай пушчы,",
                 "На цяглай-цяглай туі,",
                 "Стары-стары крумкач там",
                 "Даўно-даўно гняздуе.",
                 "",
                 "Да крумкача ўсе птушкі",
                 "Лятуць з-за небакраю",
                 "Даведацца, які лёс",
                 "Іх у жыцьці чакае.",
                 "",
                 "Ды толькі раз у сто год",
                 "Ён зыркачы расплюшчыць",
                 "На сьвет шырокі глянуць,",
                 "Падаць свой голас пушчы.",
                 "",
                 "I зноўку ціха-ціха.",
                 "Усе-усе чакаюць,",
                 "Калі-калі крумкач той",
                 "Што збаіць ім, што збаіць.",
                 "\n",
                 "Максім Танк",
                 "\n#УкрТві #БелТві"
               ]
    end
  end

  describe "split_text_into_threads/1" do
    test "1-tweet thread" do
      threads =
        PoemBot.prepare_poem_text(
          poem: poem_2(),
          author: author_2(),
          hashtags: "#УкрТві #БелТві"
        )
        |> PoemBot.split_text_into_threads()

      assert threads == [
               [
                 "Восень расьпісала",
                 "Лісьце клёнаў барвай.",
                 "Прысадамі блукаюць",
                 "Летуценьні-мары...",
                 "У стройнае бярозкі,",
                 "Бы сівізна на скронях,",
                 "Жоўтыя лісточкі",
                 "Ляцяць долу... Шолах...",
                 "\n",
                 "Юрась Півуноў",
                 "\n#УкрТві #БелТві"
               ]
             ]
    end

    test "splits long poems into multiple threads" do
      threads =
        PoemBot.prepare_poem_text(
          poem: poem_1(),
          author: author_1(),
          hashtags: "#УкрТві #БелТві"
        )
        |> PoemBot.split_text_into_threads()

      assert threads == [
               [
                 "«У цёмнай-цёмнай пушчы»",
                 "У цёмнай-цёмнай пушчы,",
                 "На цяглай-цяглай туі,",
                 "Стары-стары крумкач там",
                 "Даўно-даўно гняздуе.",
                 "",
                 "Да крумкача ўсе птушкі",
                 "Лятуць з-за небакраю",
                 "Даведацца, які лёс",
                 "Іх у жыцьці чакае.",
                 "",
                 "Ды толькі раз у сто год",
                 "Ён зыркачы расплюшчыць",
                 "На сьвет шырокі глянуць,"
               ],
               [
                 "Падаць свой голас пушчы.",
                 "",
                 "I зноўку ціха-ціха.",
                 "Усе-усе чакаюць,",
                 "Калі-калі крумкач той",
                 "Што збаіць ім, што збаіць.",
                 "\n",
                 "Максім Танк",
                 "1967",
                 "\n#УкрТві #БелТві"
               ]
             ]
    end
  end

  test "records tweet history" do
    {:ok, conn} = Exqlite.Sqlite3.open("test/test.db")
    DbHelpers.drop_tables!(conn)
    DbHelpers.create_tables!(conn)

    poem = poem_1()
    author = author_1()
    DbHelpers.insert_author(conn, [author.external_id, author.name])

    DbHelpers.insert_poem(conn, [
      poem.id,
      poem.external_link,
      poem.title,
      poem.body,
      poem.year,
      author.id
    ])

    poem = DbHelpers.get_random_poem!(conn)
    assert is_nil(poem.tweeted_at)
    author = DbHelpers.get_author_by_id!(conn, poem.author_id)
    assert author

    # No tweet history prior to this
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from tweets;")
    # i.e. no results
    :done = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)

    DbHelpers.mark_poem_as_tweeted!(conn, poem)

    # Timestamp added
    poem = DbHelpers.get_poem_by_external_id(conn, poem.external_id)
    assert String.starts_with?(poem.tweeted_at, "202")

    # Tweet history record created
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "select * from tweets;")
    {:row, result} = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.release(conn, statement)
    assert result |> List.last() == poem.id

    DbHelpers.drop_tables!(conn)
  end
end
