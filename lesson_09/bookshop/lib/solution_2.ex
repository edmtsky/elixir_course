defmodule Solution2 do

  alias BookShop, as: BS
  alias BookShop.Validator, as: V

  @spec main :: {:ok, BS.Order.t} | {:error, term}
  def main() do
    BS.test_data |> handle()
  end

  def call_handle_many_times do
    0..20 |> Enum.map(fn _ -> main() end)
  end

  @spec handle(BS.json) :: {:ok, BS.Order.t} | {:error, term}
  def handle(data) do
    state = %{incoming_data: data}
    step1(state)
  end

  def step1(%{incoming_data: data} = state) do
    case V.validate_incoming_data(data) do
      {:ok, _} -> step2(state)
      {:error, error} -> {:error, error}
    end
  end

  def step2(%{incoming_data: data} = state) do
    case V.validate_cat(data["cat"]) do
      {:ok, cat} ->
        state = Map.put(state, :cat, cat)
        step3(state)
      {:error, error} -> {:error, error}
    end
  end

  def step3(%{incoming_data: data} = state) do
    case V.validate_address(data["address"]) do
      {:ok, address} ->
        state = Map.put(state, :address, address)
        step4(state)
      {:error, error} -> {:error, error}
    end
  end

  def step4(%{incoming_data: data} = state) do
    maybe_books = Enum.map(
      data["books"],
      fn(book_data) -> BS.Book.get_book(book_data["author"], book_data["title"]) end
    )

    books_or_error = Enum.reduce(
      maybe_books,
      [],
      fn
        (_, {:error, _} = acc) -> acc
        ({:ok, book}, acc) -> [book | acc]
        ({:error, _} = e, _) -> e
      end
    )

    case books_or_error do
      books when is_list(books) ->
        state = Map.put(state, :books, books)
        step5(state)
      {:error, error} -> {:error, error}
    end
  end

  def step5(%{cat: cat, address: address, books: books}) do
    order = BS.Order.new(cat, address, books)
    {:ok, order}
  end

end
