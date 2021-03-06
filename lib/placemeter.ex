defmodule Placemeter do
    use GenServer

    alias Placemeter.Client.Point

    def start_link(token) do
        GenServer.start_link(__MODULE__, token)
    end

    def measurementpoints(pm, time_ago \\ 1000) do
        GenServer.call(pm, {:measurementpoints, time_ago}, :infinity)
    end

    def measurementpoint(pm, id, time_ago \\ 1000) do
        GenServer.call(pm, {:measurementpoint, id, time_ago}, :infinity)
    end

    def init(token) do
        {:ok, %{:token => token}}
    end

    def handle_call({:measurementpoints, time_ago}, _from, state) do
        case Placemeter.Client.measurementpoints(state.token) do
            {:ok, response} ->
                {:reply, {:ok, Enum.map(response, &get_point(state.token, &1, time_ago))}, state}
            {:error, reason} ->
                {:reply, {:error, reason}, state}
        end
    end

    def handle_call({:measurementpoint, id, time_ago}, _from, state) do
        case Placemeter.Client.measurementpoints(state.token, id) do
            {:ok, response} ->
                {:reply, {:ok, get_point(state.token, response, time_ago)}, state}
            {:error, reason} ->
                {:reply, {:error, reason}, state}
        end
    end

    def get_point(token, point, time_ago) do
        now = :erlang.system_time(:seconds)
        yesterday = now - time_ago
        case Placemeter.Client.measurementpoints(token, point.id, yesterday, now) do
            {:ok, %{"data" => data}} ->
                %Point{point | :data => data}
            {:error, reason} ->
                %{point | data: reason}
        end
    end

end
