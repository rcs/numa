express = require("express")
path = require("path")
connect = require 'connect'
async = require 'async'
fs = require 'fs'

_ = require 'underscore'


# Internal: Return some info about the request
#
# req - the request
# cb  - the callback to hit with the result
#
# Calls cb with an object, the attributes
reqAttributes = (req,cb) ->
  attributes = 
    origin: req.ip
    url: req.protocol + '://' + req.headers['host'] + req.path
    args: req.query
    headers: req.headers
    form: if req._body and _.contains(['application/x-www-form-urlencoded','multipart/form-data'], connect.utils.mime(req))
        req.body
      else
        {}
    json: if req._body and connect.utils.mime(req) == 'application/json'
        req.body
      else
        null
    data: if req._body
        ""
      else
        req.body
    files: {}


  cb attributes unless req.files
  files = {}
  # Run over each file, loading the contents into the attributes
  async.forEach _.keys(req.files), (filename,cb) ->
      fs.readFile req.files[filename].path, 'utf8',(err,data) ->
        if err
          files[filename] = null
        else
          files[filename] = data
        cb()
    , (err) ->
      cb _.extend(attributes, files: files)


# Internal: Convenience method to generate a handler that returns a whitelist of request attributes
#
# whitelist: The keys to return
#
# Returns a handler that will take a request and send the whitelisted fields in JSON format to the response
returnAttributes = (whitelist...) ->
  return (req,res,next) ->
    reqAttributes req, (fields) ->
      console.log whitelist
      if whitelist.length > 0
        res.json _.pick fields, whitelist
      else
        res.json fields




app = express()
app.enable 'trust proxy'
app.use require './lib/middleware/easy-send'
app.use express.bodyParser()
app.use express.cookieParser()

app.use express.logger('dev')

# Route: /
#
# Returns a basic response.
app.all '/', (req,res,next) ->
    # TODO
    res.text 'hi there'

# Route: /html
#
# Returns an HTML response.
app.all '/html', (req,res,next)->
    res.html '<html><body><blink>hi there</blink></body></html>'

# Route: /robots.txt
#
# Returns a robots.txt file that disallows access to /deny .
app.all '/robots.txt', (req,res,next) ->
  res.text """
  User-agent: *
  Disallow: /deny

  """

# Route: /deny
#
# Returns a basic response.
#
# Used for testing robots.txt parsers
app.all '/deny', (req,res,next) ->
  res.text """
  You shouldn't be here.
  """

# Route: /ip
#
# Returns the requesting IP in 'origin'
app.all '/ip', returnAttributes('origin')

# Route: /headers
#
# Returns the request headers in 'headers'
app.all '/headers', returnAttributes('headers')

# Route: /headers
#
# Returns the user-agent in 'user-agent'
app.all '/user-agent', (req,res,next) ->
  reqAttributes req, (fields) ->
    res.json 'user-agent': fields.headers['user-agent']

# Route Signature: <VERB> /<verb>
#
# Only responds to VERB on /verb
#
# Returns basic request infomration
app.get '/get', returnAttributes()
app.post '/post', returnAttributes()
app.put '/put', returnAttributes()
app.patch '/patch', returnAttributes()
app.delete '/delete', returnAttributes()


# Internal: Fake accept-encoding headers for connect.gzip
addAcceptGzip = (req,res,next) ->
  if req.headers['accept-encoding']
    req.headers['accept-encoding'] = req.headers['accept-encoding'] + ',gzip'
  else
    req.headers['accept-encoding'] =  'gzip'

  next()


# Route: /gzip
#
# Returns gzip-compressed basic request information and 'gzipped': true
app.all '/gzip', addAcceptGzip, connect.compress(), (req,res,next) ->
  reqAttributes req, (fields) ->
    res.json _.extend _.pick(fields, 'origin','headers','method'), gzipped: true

# Route: /redirect/:number
#
# Returns a redirect, to /redirect/number - 1 if number is greater than 1, otherwise redirects to /get
app.all '/redirect/:number', (req,res,next) ->
  res.statusCode = 302
  number = parseInt(req.params.number) || 0

  res.redirect req.protocol + "://" + req.headers['host'] + if number > 1
      "/redirect/#{number - 1}"
    else
      "/get"

  res.end()

# Route: /relative-redirect/:number
#
# Returns a relative redirect to /redirect/number - 1 if number is greater than 1, otherwise redirects to /get
app.all '/relative-redirect/:number', (req,res,next) ->
  res.statusCode = 302
  number = parseInt(req.params.number) || 0

  res.redirect if number > 1
      "/relative-redirect/#{number - 1}"
    else
      "/get"

  res.end()


# Route: /stream/:number
#
# number - the number of responses to return
#
# Query Params:
#   delay - the number of milliseconds to wait between responses (default: 200)
#
# Returns :number streaming (Transfer-Encoding: chunked) response, with a d :delay 
app.all '/stream/:number', (req,res,next) ->
  res.writeHead 200, 'Transfer-Encoding': 'chunked', 'Content-Type': 'application/json'
  delay = Math.min( parseInt(req.query.delay) || 10, 200)
  number = Math.min parseInt(req.params.number) || 10

  reqAttributes req, (fields) ->
    ret = _.pick fields, 'url','args','headers','origin'

    partialWrite = (remaining) ->
      res.write JSON.stringify(_.extend ret, remaining: remaining - 1) + "\n"
      if remaining > 1
        setTimeout ->
            partialWrite(remaining-1)
          , delay
      else
        res.end()

    partialWrite(number)

# Route: /status/:codes
#
# codes - a comma separated list of status codes (default: 200)
#
# Returns with a randomly selected status code
app.all '/status/:codes', (req,res,next) ->
  choices = req.params.codes?.split(',') || [200]

  choice = parseInt(choices[_.random(0,choices.length-1)])

  res.statusCode = choice
  res.end()

# Route: /response-headers
#
# Returns a response with headers set from query parameters
#
# Example:
#   /response-headers?foo=bar returns a response with header "foo: bar"
app.all '/response-headers', (req,res,next) ->
  for key, value of req.query
    res.setHeader key, value

  res.json req.query


# Route: /cookies
#
# Returns the cookies sent
app.all '/cookies', (req,res,next) ->
  res.json req.cookies

# Route: /cookies/set/:name/:value
#
# name - the cookie key
# value - the cookie value
#
# Returns a response with a Set-Cookie: :name=:value
app.all '/cookies/set/:name/:value', (req,res,next) ->
  res.cookie(req.params.name, req.params.value)
  res.redirect 'cookies'

# Route: /cookies/set
#
# Returns a response with a set-cookie header constructed from the query parameters
#
# Example:
# /cookies/set?things=more -> Responds with Set-Cookie: things=more; Path=/
app.all '/cookies/set', (req,res,next) ->
  for key, value of req.query
    res.cookie key, value
    console.log "setting #{key} = #{value}"

  res.redirect 'cookies'

# Internal: Grab the Basic authentication from the request
#
# req - the request to pull credentials out of
#
# Returns a hash with user and pass keys, set to null if they can't be found
suppliedAuth = (req) ->
  unknown =  {user: null, pass: null}

  return unknown unless req.headers.authorization

  [scheme, encoded] = req.headers.authorization?.split(' ')
  return unknown unless scheme and encoded

  if scheme == 'Basic'
    credentials = new Buffer(encoded, 'base64').toString()
    index = credentials.indexOf(':')
    return unknown unless index > -1

    return {
      user: credentials.slice(0,index)
      pass: credentials.slice(index+1)
    }
  else
    return unknown









# Route: /basic-auth/:user/:pass
#
# user - the username of a successful response (default: 'user')
# pass - the password of a successful response (default: 'pass')
#
# Returns a 401 if the supplied Basic credentials don't match user and pass, object with 'authenticated': true otherwise
app.all '/basic-auth/:user?/:pass?', (req,res,next) ->
  _.defaults req.params, user: 'user', pass: 'pass'

  credentials = suppliedAuth(req)
  if req.params.user == credentials.user and req.params.pass == credentials.pass
    res.json authenticated: true, user: credentials.user
  else
    res.statusCode = 401
    res.end()

# Route: /hidden-basic-auth/:user/:pass
#
# user - the username of a successful response (default: 'user')
# pass - the password of a successful response (default: 'pass')
#
# Returns a 404 if the supplied Basic credentials don't match user and pass, object with 'authenticated': true otherwise
app.all '/hidden-basic-auth/:user?/:pass?', (req,res,next) ->
  _.defaults req.params, user: 'user', pass: 'pass'

  credentials = suppliedAuth(req)
  if req.params.user == credentials.user and req.params.pass == credentials.pass
    res.json authenticated: true, user: credentials.user
  else
    res.statusCode = 404
    res.end()

# Route: /digest-auth/:user/:pass
#
# user - the username of a successful response (default: 'user')
# pass - the password of a successful response (default: 'pass')
#
# Returns a 404 if the supplied Digest credentials don't match user and pass, object with 'authenticated': true otherwise
#
# Note: Not implemented -- stub to match httpbin
app.all '/digest-auth/*', (req,res,next) ->
  res.json
    TODO: 'Still need to implement'


# Route: /delay/:number
#
# number - number of seconds to delay response
#
# Returns basic request information after :number seconds 
app.all '/delay/:number', (req,res,next) ->
  delay = Math.min(parseInt(req.params.number)|| 10, 10)

  setTimeout ->
      reqAttributes req, (fields) ->
        res.json _.pick fields,  'url','args','form','data','origin','headers','files'
    , delay*1000


# Route: /base64/string
#
# string - a base64 encoded string
#
# Returns the decoding of :strin
app.all /^\/base64\/(.*)/, (req,res,next) ->
  res.text new Buffer(req.params[0], 'base64').toString()






app.listen process.env.PORT || 3000
