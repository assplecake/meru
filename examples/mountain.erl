-module(mountain).
-compile({parse_transform, meru_transform}).

-meru_pool(default).
-meru_bucket(<<"mountains">>).
-meru_record(mountain).
-meru_keyfun(make_key).
-meru_mergefun(merge).

-export([
    test/0,
    merge/3
]).

-record(mountain, {
    name,
    range,
    planet,
    lakes = [],
    height =1,
    type = "hello",
    created_at,
    updated_at
}).

test() ->
    % construct 2 mountain records
    Chimbo = #mountain{
        name   = <<"Chimborazo">>,
        range  = <<"Cordillera Occidental">>,
        planet = <<"Earth">>,
        height = 6267,
        type   = <<"volcano">>
    },
    Oly = #mountain{
        name   = <<"Olympus Mons">>,
        range  = <<"Amazonis">>,
        planet = <<"Mars">>,
        height = 21171,
        type   = <<"volcano">>
    },

    % put our mountains in the store
    {ok, ChimboKey, Chimbo} = mountain:put(Chimbo),
    {ok, OlyKey, Oly}       = mountain:put(Oly),

    % update chimborazo
    ChimboUpdate = #mountain{
        lakes = [<<"Rio Chambo Dam">>]
    },
    {ok, ChimboKey, _MergedChimbo} = mountain:put_merge(ChimboKey, ChimboUpdate, [{lake_merge, union}]),

    % get the mountains out by key or tuple
    {ok, Chimbo2} = mountain:get(ChimboKey),
    {ok, Chimbo2} = mountain:get({<<"Chimborazo">>, <<"Cordillera Occidental">>}),
    {ok, Oly} = mountain:get(OlyKey),
    {ok, Oly} = mountain:get({<<"Olympus Mons">>, <<"Amazonis">>}),

    % deleting a deleted record should return not found
    {ok, ChimboKey} = mountain:delete({<<"Chimborazo">>, <<"Cordillera Occidental">>}),
    {ok, ChimboKey} = mountain:delete(ChimboKey),
    {ok, OlyKey} = mountain:delete(OlyKey).

%%
%% private
%%

make_key(#mountain{ name = Name, range = Range }) ->
    make_key({Name, Range});
make_key({Name, Range}) -> term_to_binary({Name, Range});
make_key(Key) when is_binary(Key) -> Key.

merge(notfound, NewMountain, _) ->
    NewMountain;
merge(OldMountain, NewMountain, MergeOpts) ->
    Lakes = case proplists:get_value(lake_merge, MergeOpts) of
        overwrite ->
            NewMountain#mountain.lakes;
        union ->
            lists:usort(OldMountain#mountain.lakes ++ NewMountain#mountain.lakes)
    end,
    OldMountain#mountain{
        lakes = Lakes,
        updated_at = calendar:universal_time()
    }.

