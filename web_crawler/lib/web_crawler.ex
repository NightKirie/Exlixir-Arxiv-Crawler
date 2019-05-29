defmodule CrawlEachPage do
  	use Supervisor

	def start_link(pages) do
		Supervisor.start_link(__MODULE__, pages)
	end

	def init(pages) do
		children = Enum.map(pages, 
			fn(page_link) ->
				worker(Child, [page_link], [restart: :transient])
			end)

		supervise(children, strategy: :one_for_one)
	end
end

defmodule Child do
	def start_link(limit) do
		pid = spawn_link(__MODULE__, :init, [limit])
		{:ok, pid}
	end

	def init(limit) do
		IO.puts "Start child with limit #{limit} pid #{inspect self()}"
		loop(limit)
	end

	def loop(0), do: :ok
	def loop(n) when n > 0 do
		IO.puts "Process #{inspect self()} counter #{n}"
		Process.sleep 2000
		loop(n-1)
	end
end

defmodule WebCrawler do
	@default_max_depth 0
	@default_headers []
	@default_options [follow_redirect: true, ssl: [{:versions, [:"tlsv1.2"]}]]
	@default_url_front "https://arxiv.org/search/?query="
	@default_url_end "&searchtype=author&size=25&start="
  	def get_links(opts \\ []) do
		author = 
			IO.gets("Input author: ")
			|> String.replace(" ", "+")
			|> String.replace("\n", "")
		url = URI.parse(@default_url_front <> author <> @default_url_end <> "0") 

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
		url
		|> to_string
		|> HTTPoison.get(context.headers, context.options)
		|> handle_response(path, url, context)
	end

  	defp handle_response({:ok, %{body: body}}, path, url, context) do
		IO.puts("Crawling \"#{url}\"...")
		path = [url | path]
		{resultPerPage, totalResult} =
		body
		# Find the line like "Showing 1–x of n results for author:"
		|> Floki.find("h1.title")
		# Get the tuple {tagName, classList, content} in return list
		|> hd
		# Change the tuple into list [tagName, classList, content]
		|> Tuple.to_list()
		# Get the content
		|> Enum.at(2)
		# Get the text in the content
		|> Enum.at(0)
		# Get all numbers in the text 
		|> (&Regex.scan(&2, &1)).(
			# Regular expression of number, return {:ok, "[0-9,]+"}
			Regex.compile("[0-9,]+")
			# Make tuple into list [:ok, "[0-9,]+"]
			|> Tuple.to_list()
			# Get compiled regular expression object                      
			|> Enum.at(1)
		)
		# Change 2-d list to 1-d list
		|> List.flatten()
		# Remove "1" in list, we don't need that
		|> tl
		# Remove "," from number larger than 999
		|> Enum.map(fn x ->
			Regex.replace(
			Regex.compile(",")
			|> Tuple.to_list()
			# Get compiled regular expression object 
			|> Enum.at(1),
			x,
			""
			)
		end)
		|> List.to_tuple()
		page_link = []
			for i <- 1..Kernel.trunc(String.to_integer(totalResult)/String.to_integer(resultPerPage))
				do
					page_link = page_link ++ [
					url
					|> URI.to_string
					|> String.replace("&searchtype=author&size=25&start=0", @default_url_end)
					|> Kernel.<>(Integer.to_string(i*25)) ]

				end
		Enum.map(page_link, fn x -> IO.puts x end)
		{:ok, super_pid} = Task.Supervisor.start_link()

		# |> Enum.map(&URI.merge(url, &1))
		# |> Enum.map(&to_string/1)
		# |> IO.puts(&1)
		# |> Enum.reject(&Enum.member?(path, &1))
		# |> Enum.map(&Task.async(fn -> get_links(URI.parse(&1), [&1 | path], context) end))
		# |> Enum.map(&Task.await/1)
		# |> List.flatten()
	end

end

