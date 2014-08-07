#
# PubNub Persistence: node.js replication handler
#
# "Connecting your worldwide apps to redis updates within 250ms"
#
# Usage: coffee src/pubnub-mongodb-replicate.coffee MONGODB_ADDR COLLECTION_NAME CHANNEL_NAME
#      - where MONGODB_ADDR is the host:port
#      - where COLLECTION_NAME is the MongoDB collection name to watch
#      - where CHANNEL_NAME is the PubNub channel to receive updates
#

PUBNUB     = require '../deps/pubnub-javascript/node.js/pubnub.js'
_          = require '../deps/underscore/underscore.js'
MongoWatch = require '../deps/mongo-watch/index.js'

# utility function for stringifying arguments
asString = (e) -> _.map(e, (x) -> x.toString())

pubnub = PUBNUB.init(
  subscribe_key : 'demo' # you should change this!
  publish_key   : 'demo' # you should change this!
)

MONGO_ADDR = (process.argv[2] || 'localhost:27017').split(":")
MONGO_HOST = MONGO_ADDR[0]
MONGO_PORT = MONGO_ADDR[1]
MONGO_COLL = process.argv[3]
CHANNEL    = process.argv[4]

# create a Mongo Watcher
watcher = new MongoWatch {format: 'pretty'} # for verbosity, add "onDebug:console.log"

# watch the collection
watcher.watch MONGO_COLL, (entry) ->
  console.log "- got event : " + JSON.stringify(entry)
  pubnub.publish {channel:CHANNEL,message:{type:'oplog',uuid:pubnub.uuid(),entry:entry}}

# Start up and go!
console.log "Replicating from MongoDB host #{MONGO_ADDR} collection #{MONGO_COLL} to PubNub channel \##{CHANNEL}"

