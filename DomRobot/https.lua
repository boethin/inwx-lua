-- Lua XML-RPC client for the INWX Domain API.
-- https://github.com/boethin/inwx-lua
--
-- Copyright (c) 2015 Sebastian Böthin <sebastian@boethin.berlin>
--
-- Extends LuaSocket's HTTP module for HTTPS requests based on LuaSec.
-- See also:
-- LuaSocket: http://w3.impa.br/~diego/software/luasocket/
-- LuaSec: https://github.com/brunoos/luasec/wiki
-- Solution adapted from http://lua-users.org/lists/lua-l/2009-02/msg00270.html
--
local http = require "socket.http"
local ssl = require "ssl"

local https = {}

-- httpParams is forwarded to socket.http.request()
-- sslParams is forwarded to ssl.wrap()
function https.request(httpParams,sslParams)

  local try = socket.try
  local protect = socket.protect

  -- create() default is socket.tcp
  function httpParams.create()
    local t = {c=try(socket.tcp())}

    function idx (tbl, key)
      return function (prxy, ...)
         local c = prxy.c
         return c[key](c,...)
      end
    end

    -- wrap tcp connect with ssl handshake
    function t:connect(host, port)
      try(self.c:connect(host, port))
      self.c = try(ssl.wrap(self.c,sslParams))
      try(self.c:dohandshake())
      return 1
    end

    return setmetatable(t, {__index = idx})
  end

  return http.request(httpParams);
end

return https
