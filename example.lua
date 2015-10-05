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

-- Request account.info to see if it works.
local ok, res = api.account:info()

for i, v in pairs(res.resData) do print ('\t', i, v) end
print("--")






