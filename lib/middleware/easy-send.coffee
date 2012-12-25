_ = require 'underscore'

# Set up basic methods on the request for fancy easy sending
#
methods =
  # Public: Return a text response
  text: (text) ->
    @setHeader 'Content-Type', 'text/plain'
    @send text
    @end()
  # Public: Return a json-encoded response
  #
  # obj - the object to encode
  #
  # If obj is not an object, we assume it's already an encoded json string
  json: (obj) ->
    @setHeader 'Content-Type', 'application/json'
    if _.isObject obj
      @send JSON.stringify obj
    else
      @send obj
    @end()
  # Public: Returns an HTML response
  #
  # html -  the HTML string
  html: (html) ->
    @setHeader 'Content-Type', 'text/html'
    @send html
    @end()


module.exports = (req,res,next) ->
  for method, body of methods
    if !res[method]?
      res[method] = body
  next()
