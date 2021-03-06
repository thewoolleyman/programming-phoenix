defmodule InfoSys.Wolfram do
  import SweetXml
  import InfoSys.Result

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    query_str
    |> fetch_xml()
    |> xpath(~x"/queryresult/pod[ contains(@title, 'Result') or
                                  contains(@title, 'Definitions')]
                            /subpod/plaintext/text()")
    |> send_results(query_ref, owner)
  end

  defp send_results(nil, query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end
  defp send_results(answer, query_ref, owner) do
    results = [%InfoSys.Result{backend: "wolfram", score: 95, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  @http Application.get_env(:info_sys, :wolfram)[:http_client] || :httpc
  defp fetch_xml(query_str) do
    # TODO: This line always prints:
    #   "warning: function InfoSys.Test.HTTPClient.request/1 is undefined (module InfoSys.Test.HTTPClient is not available)"
    #   even though tests pass.  Is something loading it without the stub HTTPClient defined?
    {:ok, {_, _, body}} = @http.request(
      String.to_char_list("http://api.wolframalpha.com/v2/query" <>
        "?appid=#{app_id()}" <>
        "&input=#{URI.encode(query_str)}&format=plaintext"))
    body
  end

  defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]
end