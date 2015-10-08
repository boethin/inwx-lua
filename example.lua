--------------------------------------------------------------------------------
-- Lua client for the DomRobot XML-RPC API.
-- https://github.com/boethin/inwx-lua
--
-- Copyright (c) 2015 Sebastian Böthin <sebastian@boethin.berlin>
--------------------------------------------------------------------------------

-- Sample client.
--

-- namespace DomRobot.
-- Make sure the path is found by lua.
local DomRobot = {
  API = require "DomRobot/API",
  Client = require "DomRobot/Client"
}

-- SSL parameters.
-- See: https://github.com/brunoos/luasec/wiki
local SSLParams = {
  mode = "client",
  protocol = "sslv23",
  cafile = "/etc/ssl/certs/ca-certificates.crt",
  verify = "peer",
  options = "all",
}

-- OT&E API request parameters (Testing)
-- ==> Insert your OT&E username/password <==
local OTE_creds = {
  host = "api.ote.domrobot.com",
  user = "[ username here ]",
  pass = "[ password here ]",
  lang = "en"
}

--[[
-- API request parameters (Production)
--
local PROD_creds = {
  host = "api.domrobot.com",
  user = "[ username here ]",
  pass = "[ password here ]",
  lang = "en"
}
--]]

-- Set to PROD_creds in order to access production environment.
local creds = OTE_creds

-- Save authentication cookie (make tsure the path is writable).
-- ==> Remove the file when the cookie is expired. <==
local authFile = creds.host..".txt"

-- Create API client instance.
local api = DomRobot.API(DomRobot.Client(DomRobot.API,creds.host,SSLParams))

-- Authenticate or load cookie file
api:persistentLogin(authFile,creds.user,creds.pass,creds.lang)

local ok, res

--------------------------------------------------------------------------------
-- Example:
-- Request account.info() to see if it works.
ok, res = api.account:info()
if ok then
  -- request successful:
  assert(res.resData.email)
  print("request ok: your email is:", res.resData.email)
else
  -- request failed
  for i, v in pairs(res) do print ('\t', i, v) end
end

--------------------------------------------------------------------------------
-- Example: 
-- Check some domains for availabilty.
-- unpack() Lua table to send XML-RPC array
-- DOES NOT WORK PROPERLY
ok, res = api.domain:check( { domain = unpack({ "example.net", "example.global", "foo.bar" }) } )
if ok then
  -- request successful:
  assert(type(res.resData.domain) == "table")
  for i, v in pairs(res.resData.domain) do 
    print ('\t', i, v.domain,v.avail,v.status ) 
  end
else
  -- request failed
  for i, v in pairs(res) do print ('\t', i, v) end
end



