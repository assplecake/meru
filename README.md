# meru

[UNDER CONSTRUCTION] Add methods to your erlang modules that map to riak objects.

## installation

Install as a rebar dependency:

```erlang
{meru, ".*", {git, "git@github.com:assplecake/meru.git", "master"}}
```

## usage

Add the `meru_transform` parse transform to a module that you would like to wrap a riak object:

```erlang
-module(user).

-compile({parse_transform, meru_transform}).
```

Define a record that represents the data stored in riak. In this case, we'll use a user record:

```erlang
-record(user, {
  name,
  email,
  encrypted_password
}).
```

Now we'll need a key function, which serves to generate the key for the object in riak. Usually we'll define a binary clause to represent the key, as well as a clause that takes the record as an input. 

```erlang
make_key(#user{ email = Email }) when is_binary(Email) ->
  Email;
make_key(Key) when is_binary(Key) -> Key.
```

When saved objects are updated, we'll need the merge logic, so next define a merge function that will be passed 3 arguments - the saved record, the new record, and a list of options that you can pass through when updating. If a record is not found to merge, meru will call the merge function with `notfound` as the first argument:

```erlang
merge(notfound, NewUser, _) ->
  NewUser;
merge(OldUser, NewUser, Options) ->
  OldUser#user{
    name = NewUser#user.name
    encrypted_password = NewUser#user.encrypted_password
  }.
```

Set the module attributes for riak pool, riak bucket, record name, key function, and merge function:

```erlang
-meru_pool(default).
-meru_bucket(<<"users">>).
-meru_record(user).
-meru_keyfun(make_key).
-meru_mergefun(merge).
```

Note: meru serializes records as proplists for storage in riak. It's possible to have different serialization strategies in the future.

Once your module is compiled, meru will add and export the following functions:

```erlang
%% convenience functions for working with records:
Record    = ?MODULE:new()
Record    = ?MODULE:new(Proplist)
Proplist  = ?MODULE:record_to_proplist(Record)
Record    = ?MODULE:proplist_to_record(Proplist)

%% riak functions:
{ok, Obj} = ?MODULE:get(KeyOrRecord) % KeyOrRecord is whatever arguments your keyfun can take
{ok, Key, Record} = ?MODULE:put(Record)      % meru returns a key and the record
{ok, Key, MergedRecord} = ?MODULE:put_merge(Record, Options) % the riak object is read and merged with your mergefun
{ok, Key, MergedRecord} = ?MODULE:put_merge(Key, Record, Options) % in the case that you want to pass your key explicitly
{ok, Key} = ?MODULE:delete(KeyOrRecord)

%% in addition to the above riak functions, each function can also take a riakc_pb_socket pid as the first argument:
{ok, Obj} = ?MODULE:get(Pid, KeyOrRecord)
{ok, Key, Record} = ?MODULE:put(Pid, Record)
{ok, Key, MergedRecord} = ?MODULE:put_merge(Pid, Record, Options)
{ok, Key, MergedRecord} = ?MODULE:put_merge(Pid, Key, Record, Options)
{ok, Key} = ?MODULE:delete(Pid, KeyOrRecord)
```

See the [examples directory](https://github.com/assplecake/meru/tree/master/examples) for complete examples.

## migrations
You can have meru passively migrate your data from one pool/bucket to another pool/bucket. To enable, add the migration module attribute with `{OldPool, OldBucket, MigrateFun}`. The new pool and bucket are just specified as the regular `meru_pool` and `meru_bucket` attributes:

```erlang
-meru_pool(default).
-meru_bucket(<<"users">>).
-meru_record(user).
-meru_keyfun(make_key).
-meru_mergefun(merge).
-meru_migration({legacy_default, <<"legacyusers">>, migrate}).
```

You'll then need to export a migrate function that receives a record and must return a record. It's called when the data is first migrated:

```erlang
migrate(User) ->
    User#user{ migrated = true }.
```

Migration happens when a `get` operation returns `not_found` for the new pool/bucket. There will definitely be a performance impact by enabling a migration, especially when a record is not found in either pool/bucket pair, since the migration will continue to check both. Use it sparingly.

## helper modules

### meru_riak

`meru_riak` takes the same commands as riak protobuffs client `riakc_pb_socket`, but doesn't require obtaining a pid. You must however specify a pool from which to obtain the pid.

```erlang
{ok, RiakObject} = meru_riak:get(meru_riak_pool_default, Bucket, Key).
```

Note: only the most used functions (`get`, `put`, `delete`, `mapred`) are exported for now with the default timeouts. Use `call/2` to call a `riakc_pb_socket` function directly:

```erlang
{ok, Keys} = meru_riak:call(meru_riak_pool_default, list_keys, [Bucket, Timeout]).
```

There's also a transaction function to obtain a pid for multiple operations:

```erlang
meru_riak:transaction(meru_riak_pool_default, fun (Pid) ->
  meru_riak:get(Pid, Bucket, Key),
  meru_riak:call(Pid, list_keys, [Bucket])
end).
```

## license

Apache 2.0 http://www.apache.org/licenses/LICENSE-2.0.html
