# Numa - A Swiss Army HTTP Server

Test all kinds of HTTP requests and responses.

Freely hosted at [Heroku](http://numa.herokuapp.com)

## Endpoints

### Grab Bag

[/](/) This page

[/ip](/ip) Returns  Origin IP

[/html](/html) Returns an HTML rendered page

[/stream/:n](/stream/10?delay=10) Returns :number streaming (Transfer-Encoding: chunked) response, with a delay between each specified in ?delay

[/status/:codes](/status/418) Returns a randomly selected status code from :codes

[/delay/:n](/delay/5) Returns basic request information after :n seconds

[/base64/:string](/base64/WW91J3ZlIGhhY2tlZCB0aGUgbWF0cml4Lg==) Returns the decoded :string

### Headers

[/headers](/headers) Returns the request headers in 'headers'

[/user-agent](/user-agent) Returns the user-agent in 'user-agent'

[/response-headers](/response-headers?X-Powered-By=Magic) Returns a response with headers set from query parameters

### Robots
[/robots.txt](/robots.txt) Returns a robots.txt file that disallows access to /deny .

[/deny](/deny) Returns a basic response from a URL that's denied by robots.txt


### HTTP Methods

They'll respond with a 404 to non-matching methods

[/get](/get) Returns a basic response to GET requests

[/put](/put) Returns a basic response to PUT requests

[/post](/post) Returns a basic response to POST requests

[/patch](/patch) Returns a basic response to PATCH requests

[/delete](/delete) Returns a basic response to DELETE requests

[/gzip](/gzip) Returns gzip-compressed basic request response with 'gzipped': true

### Redirects

[/redirect/:n](/redirect/1) Returns a 302 redirect to /redirect/number - 1 if number is greater than 1, otherwise redirects to /get

[/relative-redirect/:n](/relative-redirect/1) Returns a relative redirect to /redirect/number - 1 if number is greater than 1, otherwise redirects to /get


### Cookies
[/cookies](/cookies) Returns the cookies sent

[/cookies/set/:name/:value](/cookies/set/fun/kitties) Returns a response with a Set-Cookie: :name=:value

[/cookies/set](/cookies/set?fancy=feast) Returns a response with a set-cookie header constructed from the query parameters

### Authentication

[/basic-auth/:user/:pass](/basic-auth/user/pass) Prompts for authentication and returns 401 unless the provided credentials match :user and :pass

[/hidden-basic-auth/:user/:pass](/hidden-basic-auth/user/pass) Prompts for authentication and returns 401 unless the provided credentials match :user and :pass

[/digest-auth](/digest-auth) Doesn't work


## Description

[Numa](http://en.wikipedia.org/wiki/Numa_Pompilius) was the second king of Rome.


## Examples
```sh
$ curl numa.herokuapp.com/ip
```

```javascript
{
  "origin": "127.0.0.1"
}
```

```sh
$ curl numa.herokuapp.com/get
```
```javascript
{
  "origin": "127.0.0.1",
  "url": "http://localhost:3000/get",
  "args": {},
  "headers": {
    "user-agent": "curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5",
    "host": "localhost:3000",
    "accept": "*/*"
  },
  "form": {},
  "json": null,
  "data": {},
  "files": {}
}
```

```sh
$ curl -i localhost:3000/status/418
```

```javascript
HTTP/1.1 418 I'm a teapot
X-Powered-By: Express
Date: Tue, 25 Dec 2012 21:48:10 GMT
Connection: keep-alive
Transfer-Encoding: chunked
```



## See Also

[httpbin.org](http://httpbin.org) httpbin, the inspiration for this project

[GirlieMac](http://www.flickr.com/photos/girliemac/) The fabulous author of the status images

