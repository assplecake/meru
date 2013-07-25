-module(meru_riak).
-compile({inline, [call_transaction/2]}).

-export([
    start_link/1,
    get/2,
    put/1,
    delete/2
]).

%%
%% API.
%%
start_link([Host, Port]) ->
    riakc_pb_socket:start_link(Host, Port).

get(Bucket, Key) ->
    call_transaction(get, [Bucket, Key]).

put(RObj) ->
    call_transaction(put, [RObj]).

delete(Bucket, Key) ->
    call_transaction(delete, [Bucket, Key]).

%%
%% private
%%
call_transaction(Method, Args) ->
    poolboy:transaction(?MODULE, fun (Worker) -> 
        erlang:apply(riakc_pb_socket, Method, [Worker | Args]) end).
