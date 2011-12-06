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

```rb
class Schlep
  require 'json'
  require 'redis'

  def self.event(type, message)
    # json validation/conversion
    # message = message.to_json unless message.is_a? String

    envelope = {
      :timestamp => Time.now.to_f,
      :app => "Test",
      :host => `hostname`.split(".").first,
      :type => type
      :message => message
    }.to_json

    Redis.rpush 'schlep', envelope
  end
end

Schlep.event "test", { :schlep => "rocks" }
```


