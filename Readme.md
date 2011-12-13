# Schlep

Schlep provides a simple interface for logging and broadcasting events.

![Schlep](https://github.com/Movitas/schlep/raw/master/Readme.png)

## Keyspace

```
# Input
schlep                  # (List) Input queue for all events

# Storage
schlep:stores           # (Set)  Types that will be stored in MongoDB
schlep:store:{type}     # (List) Queues for storage

# Queues
schlep:queues           # (Set)  Types that will be sent to worker queues
schlep:queue:{type}     # (List) Queues for workers

# Events
schlep:event:{type}     # (Pub/Sub) Channels for listening to events

# Statistics
schlep:statistics       # (Sorted set) Counters for various statistics
schlep:statistic:apps   # (Sorted set) All apps seen, with counters
schlep:statistic:hosts  # (Sorted set) All hosts seen, with counters
schlep:statistic:types  # (Sorted set) All types seen, with counters
```

## Envelope

The string submitted should be valid JSON, formatted as follows:

```js
{
    "timestamp": 1322770966.80738,
    "app": "Test",
    "host": "localhost"
    "type": "something",
    "message": {
        "a": 1,
        "b": "two"
    }
}
```

## Reference implementation

There's a Ruby client over at [Movitas/schlep-ruby](http://github.com/Movitas/schlep-ruby).
That's probably the best place to start if you're interested in building your own client in another language.
