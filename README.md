# WebCrawler write in elixir, with both supervisor & non-supervisor crawler, target page is https://arxiv.org 

## Geting started

1. Inside this folder
2. Ubuntu:
	1. Add Erlang Solutions repo: `wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb`
	2. Run: `sudo apt-get update`
	3. Install the Erlang/OTP platform and all of its applications: `sudo apt-get install esl-erlang`
	4. Install Elixir: `sudo apt-get install elixir`
3. Get dependency packages `mix deps.get`
4. Run `iex -S mix`
5. Run `WebCrawlerNoSupervisor.get_links` for crawling with no supervisor, or run `WebCrawlerSupervisor` for crawling with supervisor
6. Input an author you want to search, ex. Ian Goodfellow
7. That's it! Wait for the crawling!
P.S. Don't try to search with some famaliar name like "Paul", too much result will cause to much crawling, and you'll probably get ban by the arxiv.org


If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `web_crawler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:web_crawler, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/web_crawler](https://hexdocs.pm/web_crawler).
