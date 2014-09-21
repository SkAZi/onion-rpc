defmodule Onion.RPC do
    require Logger
    import Onion
    use Onion.RPC.Database

    defmiddleware Resource do

        def init(opts) do
            model = opts[:model]
            [{Onion.Common.ValidateArgs, [optional: model.fields, strict: true]}, {Resource, opts}]
        end

        def process(:in, state = %{request: request}, opts) do
            model = opts[:model]
            allow = opts[:allow] || ["GET"]

            obj = try do
                request[:args] |> model.atomise
            rescue
                _e in ArgumentError -> nil
            end

            res = case {request[:method], allow == "*" or request[:method] in allow, obj} do
                {_, _, nil} -> {nil, false}
                {"GET", true, obj} -> 
                    case model.all_pk?(obj) do
                        true -> {model.get(obj), false}
                        false -> {model.select(obj, 50), true}
                    end
                {"POST", true, obj} -> {model.new(obj) |> model.insert, false}
                {"PUT", true, obj} -> 
                    case model.all_pk?(obj) do
                        true -> {model.new(obj) |> model.update, false}
                        false -> {nil, false}
                    end
                {"PATCH", true, obj} -> {model.update(obj), false}
                {"DELETE", true, obj} -> {model.delete(obj), false}
                _ -> {nil, false}
            end

            Logger.info inspect res

            case res do
                {nil, _} -> reply(state, 400, "Bad request") |> break
                res -> put_in(state, [:response, :query], res)
            end
        end

    end

end