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
                {_, _, nil} -> nil
                {"GET", true, obj} -> 
                    case model.all_pk?(obj) do
                        true -> model.get(obj)
                        false -> model.select(obj, 50)
                    end
                {"POST", true, obj} -> model.new(obj) |> model.insert
                {"PUT", true, obj} -> 
                    case model.all_pk?(obj) do
                        true -> model.new(obj) |> model.update
                        false -> nil
                    end
                {"PATCH", true, obj} -> model.update(obj)
                {"DELETE", true, obj} -> model.delete(obj)
                _ -> nil
            end

            Logger.info res

            case res do
                nil -> reply(state, 400, "Bad request") |> break
                _ -> put_in(state, [:response, :query], res)
            end
        end

    end

end