# PubNub Persistence - MongoDB Replication Edition

Welcome to a growing collection of persistence adapters for
PubNub using Node.JS. In this sample, we present a proof-of-concept
for globally replicating MongoDB data using PubNub.

NOTE: this is not production-ready! It is supposed to provoke
inspiration and conversation while we work, test and get the
bugs out. Thanks so much for checking it out!

# Before you begin

* Download & install mongodb version 2.4.10 - let us know if you're using a different version you'd like us to check out!
* Install the node.js mongodb native driver using `npm install mongodb -g`
* IMPORTANT! Make sure that you register for a new PubNub account, and use your own subscription key for any of these samples.
* Note that all dependencies should be included in the "deps" folder - let us know if we missed one!
* If you need to know the revision or source of a dependency, check the GIT_REV or .git_config files in that directory respectively
* Note that this has not been scale tested! It is merely nifty and awesome...


# MongoDB Configuration

For this example, try out the following steps when configuring a test MongoDB instance:

1. Start MongoDB using a replication set argument, for example: `$ ./bin/mongod --replSet test --dbpath ./data`
2. Start a mongo shell and configure MongoDB as follows: `> rs.initiate({_id: "test", members: [{_id: 0, host: "127.0.0.1:27017"}]})`


# Understanding MongoDB Replication

MongoDB uses Replication Sets as a primary grouping mechanism for replication. Within
each replica set, one node is configured as a primary. If the cluster detects a primary
node failure, a secondary node will be elected to become a new master. The oplog is
replicated to each node and contains itemized updates which are applied to each node's
state in-order to determine the current state of the collection. The oplog also has
a fixed size which determines the number of events stored in its history.

For more information, check out:

* [MongoDB Replication](http://docs.mongodb.org/manual/core/replication/)
* [More about the MongoDB Replication process](http://docs.mongodb.org/manual/core/replication-process/)
* [The MongoDB Oplog](http://docs.mongodb.org/manual/core/replica-set-oplog/)


# Running the code: Starting a MongoDB Replicator

To start a MongoDB replication client, use this command:

```
$ node lib/pubnub-mongodb-replicate.js localhost:27017 test.posts mongochan
```

This starts up the replication process. You should see something like this:

```
Replicating from MongoDB host localhost,27017 collection test.posts to PubNub channel #mongochan
```

Now, perform a few operations on your collection, for example:

* insert `{"email":"dude@dude.com"}`
* insert `{"email":"dude@dude.com"}` (again)
* insert `{"email":"dude@dude.com"}` (again)
* delete `{"email":"dude@dude.com"}`

If you're using the mongodb nodejs client, you'd do something like this:

```javascript
var Db, Server, client, _ref;
_ref = require('mongodb'), Server = _ref.Server, Db = _ref.Db;
client = new Db('test', new Server('localhost', 27017), { w: 1 });

client.open(function() {
  return client.collection('posts', function(err, users) {
    // QUESTION: to insert?
    // return users.insert({
    //   email: 'dude@dude.com'
    // }, function() {
    //   console.log('inserted', arguments);
    //   return client.close();
    // });
    
    // or to remove?
    // return users.remove({
    //   email: 'dude@dude.com'
    // }, function() {
    //   console.log('removed', arguments);
    //   return client.close();
    // });
  });
});
```

Whoa, that's pretty awesome! You should see something like:

```
- got event : {"timestamp":"2014-08-07T23:30:56.000Z","operation":"insert","namespace":"test.posts","operationId":"6803106416156573117","targetId":"53e40c30319f89d50449a2ec","data":{"email":"dude@dude.com","_id":"53e40c30319f89d50449a2ec"}}
- got event : {"timestamp":"2014-08-07T23:30:58.000Z","operation":"insert","namespace":"test.posts","operationId":"-2174870028769766600","targetId":"53e40c32f9ed73d60489f6a5","data":{"email":"dude@dude.com","_id":"53e40c32f9ed73d60489f6a5"}}
- got event : {"timestamp":"2014-08-07T23:30:59.000Z","operation":"insert","namespace":"test.posts","operationId":"142163094440079417","targetId":"53e40c33e8dec8d704d42169","data":{"email":"dude@dude.com","_id":"53e40c33e8dec8d704d42169"}}
- got event : {"timestamp":"2014-08-07T23:31:11.000Z","operation":"d","namespace":"test.posts","operationId":"-4913411279733964820","targetId":"53e40c30319f89d50449a2ec","data":{"_id":"53e40c30319f89d50449a2ec"}}
- got event : {"timestamp":"2014-08-07T23:31:11.000Z","operation":"d","namespace":"test.posts","operationId":"7283086471205556774","targetId":"53e40c32f9ed73d60489f6a5","data":{"_id":"53e40c32f9ed73d60489f6a5"}}
- got event : {"timestamp":"2014-08-07T23:31:11.000Z","operation":"d","namespace":"test.posts","operationId":"-3170442760649383739","targetId":"53e40c33e8dec8d704d42169","data":{"_id":"53e40c33e8dec8d704d42169"}}
```
Pretty awesome! That means that the replication client saw the update,
and sent it out on the "mongochan" channel.

What happened? The replication client connected to your MongoDB instance,
started listening to the oplog, and sent oplog change events to the PubNub
channel "mongochan". The cool thing is that even though it was one operation,
the "delete" operation removed three records under the hood, so there are
three entries in the oplog.


# Running the code: Starting a replication listener

To start a MongoDB replication listener, use this command:

```
$ node lib/pubnub-mongodb-listen-simple.js mongochan
```

This starts a listener on the given pubnub channel. You can
modify the listener to do whatever you want with the data
it receives! (This one just logs to console)

As you perform updates, you should see messages like this:

```
got from #mongochan: {"type":"entity","uuid":"84a4f60a-387a-444a-bc8a-f98c62b34dc4","entity":{"timestamp":"2014-08-07T23:28:53.000Z","operation":"d","namespace":"test.posts","operationId":"-8558837213000696141","targetId":"53e40b580bbdf2c504b1dc8c","data":{"_id":"53e40b580bbdf2c504b1dc8c"}}}
got from #mongochan: {"type":"entity","uuid":"d0a1d8eb-0882-48ec-831a-a547378073b5","entity":{"timestamp":"2014-08-07T23:28:53.000Z","operation":"d","namespace":"test.posts","operationId":"5486915442404339531","targetId":"53e40b64f6f6f3c70407f7c4","data":{"_id":"53e40b64f6f6f3c70407f7c4"}}}
```


# Summing it all up

We hope you enjoyed this example of replicating MongoDB data using PubNub and Node.JS.
In the future, we'll implement and review more MongoDB functionality, and start getting
this sample code a bit more production-ready. If you run into any issues or have any
suggestions for making this more awesome, please drop us a line!



