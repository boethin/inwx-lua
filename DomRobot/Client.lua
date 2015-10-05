--------------------------------------------------------------------------------
-- Lua client for the DomRobot XML-RPC API.
-- https://github.com/boethin/inwx-lua
--
-- Copyright (c) 2015 Sebastian Böthin <sebastian@boethin.berlin>
--------------------------------------------------------------------------------

-- externals
local io        = require "io"
local ltn12     = require "ltn12"
local xmlrpc    = require "xmlrpc"
local https     = require "DomRobot/https"

-- namespace DomRobot
local DomRobot = {}

-- DomRobot.Client
--
DomRobot.Client = {}
DomRobot.Client.__index = DomRobot.Client

setmetatable(DomRobot.Client, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

-- DomRobot.Client c'tor
function DomRobot.Client.new(api,host,ssl_args,authCookie)
  local self = setmetatable({}, DomRobot.Client)
  
  assert(type(host) == "string")
  self.api = api
  self.host = host
  self.ssl_args = ssl_args
  self.authCookie = authCookie
  return self
end

function DomRobot.Client:call(object,method,request,expectedCode)
  -- argument type check
  assert(type(object) == "string", "Invalid argument 'object': string value expected")
  assert(type(method) == "string", "Invalid argument 'method': string value expected")

  -- xmlrpc encoding
  local requestBody = xmlrpc.clEncode(self.api.methodName(object,method),request or {})
  
  -- HTTPS POST request
  local responseBody = {}
  local request_ok, http_status, response_headers = https.request({
		url = self.api.url(self.host),
		source = ltn12.source.string(requestBody),
		sink = ltn12.sink.table(responseBody),
		headers = self.api.headers(tostring(requestBody:len()),self.authCookie),
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
    assert(results.code == expectedCode, self.api.failure(object,method,results))
  end
  return ok, results, response_headers
end


function DomRobot.Client:login(user,pass,lang)
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
  self.authCookie = self.api.authMatch(cookie)
  assert(self.authCookie, "Missing authentication token: " .. cookie)
  
  return self.authCookie
end

function DomRobot.Client:persistantLogin(file,user,pass,lang)
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

  assert(self.api.authMatch(self.authCookie))
  return self.authCookie
end

return DomRobot.Client
