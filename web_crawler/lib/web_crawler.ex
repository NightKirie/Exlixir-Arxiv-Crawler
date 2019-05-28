defmodule WebCrawler do
  @default_max_depth 0
  @default_headers []
  @default_options [follow_redirect: true, ssl: [{:versions, [:"tlsv1.2"]}]]
  @default_url "https://arxiv.org/search/?query=Bob&searchtype=author&abstracts=show&order=-announced_date_first&size=25&start=0"
  def get_links(opts \\ []) do
    url = URI.parse(@default_url)

    context = %{
      max_depth: Keyword.get(opts, :max_depth, @default_max_depth),
      headers: Keyword.get(opts, :headers, @default_headers),
      options: Keyword.get(opts, :options, @default_options),
      host: url.host
    }

    get_links(url, [], context)
    # |> Enum.map(&to_string/1)
    # |> Enum.uniq()
    # |> length
  end

  defp get_links(url, path, context) do
    if continue_crawl?(path, context) and crawlable_url?(url, context) do
      url
      |> to_string
      |> HTTPoison.get(context.headers, context.options)
      |> handle_response(path, url, context)
    else
      [url]
    end
  end

  defp continue_crawl?(path, %{max_depth: max_depth}) when length(path) > max_depth, do: false
  defp continue_crawl?(_, _), do: true

  defp crawlable_url?(%{host: host}, %{host: initial}) when host == initial, do: true
  defp crawlable_url?(_, _), do: false

  defp handle_response({:ok, %{body: body}}, path, url, context) do
    IO.puts("Crawling \"#{url}\"...")
    path = [url | path]
    {resultPerPage, totalResult} = body 
                            |> Floki.find("h1.title")   # Find the line like "Showing 1–x of n results for author:"
                            |> hd                       # Get the tuple {tagName, classList, content} in return list
                            |> Tuple.to_list            # Change the tuple into list [tagName, classList, content]
                            |> tl                       
                            |> tl
                            |> hd                       # Get content
                            |> hd                       # Get text in the content
                            |> (&Regex.scan(&2, &1)).(          # Get all numbers in the text 
                                    Regex.compile("[0-9,]+")    # Regular expression of number, return {:ok, "[0-9,]+"}
                                        |> Tuple.to_list            # Make tuple into list [:ok, "[0-9,]+"]
                                        |> tl                       
                                        |> hd                       # Get compiled regular expression object
                                )
                            |> List.flatten             # Change 2-d list to 1-d list
                            |> tl                       # Remove "1" in list, we don't need that
                            |> Enum.map(                # Remove "," from number larger than 999
                                    fn x -> Regex.replace(
                                        (Regex.compile(",")
                                            |> Tuple.to_list
                                            |> tl
                                            |> hd),
                                        x,
                                        ""
                                    ) end
                                )
                            |> List.to_tuple


    #|> Enum.map(&URI.merge(url, &1))
    #|> Enum.map(&to_string/1)
    #|> IO.puts(&1)
    # |> Enum.reject(&Enum.member?(path, &1))
    # |> Enum.map(&Task.async(fn -> get_links(URI.parse(&1), [&1 | path], context) end))
    # |> Enum.map(&Task.await/1)
    # |> List.flatten()
  end

  defp handle_response(_response, _path, url) do
    [url]
  end
end
