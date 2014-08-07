{Server, Db} = require 'mongodb'
_ = require '../../lodash/index.js'

module.exports = ({db, host, port, dbOpts, username, password}, done) ->
  _.merge {native_parser: true}, dbOpts
  client = new Db db, new Server(host, port), dbOpts

  client.open (err) ->
    return done(err) if err

    # authenticate if credentials were provided
    if username? or password?
      client.authenticate username, password, {authdb:'admin'}, (err, result) ->
        done err, client

    else
      done err, client
