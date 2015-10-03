-- XML-RPC client for the INWX Domain API in Lua.
--
-- Copyright (c) 2015 Sebastian Böthin <sebastian@boethin.berlin>
--
-- Project home: https://github.com/boethin/inwx-lua

-- import global symbols
local assert = assert
local type = type
local pairs = pairs
local table = table
local require = require
local setmetatable = setmetatable
local tostring = tostring
local print = print

module("DomRobot/Client")

-- externals
local io = require "io"
local socket = require "socket"
local http = require "socket.http"
local ltn12 = require "ltn12"
local ssl = require "ssl"
local xmlrpc = require "xmlrpc"

local DomRobot = {}
DomRobot.__index = DomRobot

setmetatable(DomRobot, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function DomRobot.url(host)
  return "https://" .. host .. ":443/xmlrpc/"
end

function DomRobot.methodName(object,method)
  return object .. "." .. method
end

-- Error message
function DomRobot.failure(object,method,response)
  return "Server replied to " .. DomRobot.methodName(object,method) ..  ": " ..
    tostring(response.code) .. " - " .. response.msg
end

function DomRobot.authMatch(cookie)
  -- cookie looks like: "domrobot=5599118952f13f5a00a47f3f2fa7b1a5; path=/"
  return cookie:match("^domrobot=[^;]+")
end

function DomRobot.headers(contentLength,authCookie)
  local h = {
    ["content-type"] = "text/xml; charset=utf-8"
    -- add more custom headers here
	}
	if contentLength then h["content-length"] = contentLength end
	if authCookie then h["cookie"] = authCookie end
	return h
end

--------------------------------------------------------------------------------
-- DomRobot.Client instance
--

local function httpsRequest(http_args,ssl_args)

  local try = socket.try
  local protect = socket.protect

  -- create() default is socket.tcp
  function http_args.create()
    local t = {c=try(socket.tcp())}

    function idx (tbl, key)
      print("idx " .. key)
      return function (prxy, ...)
         local c = prxy.c
         return c[key](c,...)
      end
    end

    -- wrap tcp connect with ssl handshake
    function t:connect(host, port)
      print ("proxy connect ", host, port)
      try(self.c:connect(host, port))
      print ("connected")
      self.c = try(ssl.wrap(self.c,ssl_args))
      print("wrapped")
      try(self.c:dohandshake())
      print("handshaked")
      return 1
    end

    return setmetatable(t, {__index = idx})
  end

  assert(type(http_args.url) == "string")
  for i, v in pairs(http_args) do print ('\t', i, v) end
  print("--")

  return http.request(http_args);
end

--------------------------------------------------------------------------------
-- DomRobot.Client instance
--

-- constructor
function DomRobot.new(host,ssl_args,authCookie)
  local self = setmetatable({}, DomRobot)
  
  assert(type(host) == "string")
  self.host = host
  self.ssl_args = ssl_args
  self.authCookie = authCookie
  return self
end

function DomRobot:call(object,method,request,expectedCode)
  -- argument type check
  assert(type(object) == "string", "Invalid argument 'object': string value expected")
  assert(type(method) == "string", "Invalid argument 'method': string value expected")

  -- xmlrpc encoding
  local requestBody = xmlrpc.clEncode(DomRobot.methodName(object,method),request or {})
  
  -- HTTPS POST request
  local responseBody = {}
  local request_ok, http_status, response_headers = httpsRequest({
		url = DomRobot.url(self.host),
		source = ltn12.source.string(requestBody),
		sink = ltn12.sink.table(responseBody),
		headers = DomRobot.headers(tostring(requestBody:len()),self.authCookie),
		method = "POST"
	}, self.ssl_args)

	assert(request_ok, "Request failed: " .. http_status)
	assert(http_status == 200, "HTTP Status: " .. http_status)

  ok, results = xmlrpc.clDecode(table.concat(responseBody))

  -- at least require this
  assert(ok, "Did not get a successful xmlrpc response.")
  assert(type(results.code) == "number", "Invalid field 'code' in response data.")
  assert(type(results.msg) == "string", "Invalid field 'msg' in response data.")

   for i, v in pairs(results) do print ('\t', i, v) end
   print("--")

  if expectedCode then -- assert expected result
    assert(results.code == expectedCode, DomRobot.failure(object,method,results))
  end
  return ok, results, response_headers
end


function DomRobot:login(user,pass,lang)
  self.authCookie = nil -- reset member

  -- send request
  local ok, results, responseHeaders = self:call("account","login", {
    user = user,
    pass = pass,
    lang = lang
  }, 1000)
  
  -- read authentication cookie
  local cookie = responseHeaders["set-cookie"]
  assert(cookie, "No authentication cookie was received.")
  self.authCookie = DomRobot.authMatch(cookie)
  assert(self.authCookie, "Missing authentication token: " .. cookie)
  
  return self.authCookie
end

function DomRobot:persistantLogin(file,user,pass,lang)
  self.authCookie = nil -- reset member

  -- use persistent authentication
  local f = io.open(file, "r")
  if f ~= nil then -- file exists
    self.authCookie = f:read("*all")
    io.close(f)
  else -- send authentication request and save to file
    local a = self:login(user,pass,lang)
    f = io.open(file, "w")
    f:write(a)
    f:close()
  end

  assert(DomRobot.authMatch(self.authCookie))
  return self.authCookie
end


return DomRobot
