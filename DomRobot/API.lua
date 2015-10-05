--------------------------------------------------------------------------------
-- Lua client for the DomRobot XML-RPC API.
-- https://github.com/boethin/inwx-lua
--
-- Copyright (c) 2015 Sebastian Böthin <sebastian@boethin.berlin>
--------------------------------------------------------------------------------

-- namespace DomRobot
local DomRobot = {}

-- DomRobot.API
-- Interface specification.
DomRobot.API = {

  url = function(host)
    return "https://" .. host .. ":443/xmlrpc/"
  end,

  methodName = function(object,method)
    return object .. "." .. method
  end,

  -- Error message
  failure = function (object,method,response)
    return "Server replied to " .. DomRobot.API.methodName(object,method) ..  ": " ..
      tostring(response.code) .. " - " .. response.msg
  end,

  authMatch = function(cookie)
    -- cookie looks like: "domrobot=5599118952f13f5a00a47f3f2fa7b1a5; path=/"
    return cookie:match("^domrobot=[^;]+")
  end,

  headers = function(contentLength,authCookie)
    local h = {
      ["content-type"] = "text/xml; charset=utf-8"
      -- add more custom headers here
  	}
  	if contentLength then h["content-length"] = contentLength end
  	if authCookie then h["cookie"] = authCookie end
  	return h
  end,

  -- metatable:
  -- Any other symbol is treated as API object namespace, providing a set of
  -- functions and thus 'api.object:method(args)' calls.
  mt = {
    __index = function(table,key)
      return DomRobot.API.Object.new(table.client,key)
    end
  },
  
  -- DomRobot.API c'tor
  new = function(client)
    local self = setmetatable({}, DomRobot.API.mt)
    self.client = client
  	return self
  end,

  Object = {

    -- metatable:
    -- Any method call is forwarded to client's call() function.
    mt = {
      __index = function(obj,fun)
        return function(s,a) return s.client:call(obj.name,fun,a) end
      end
    },

    -- DomRobot.API.Object c'tor
    new = function(client,name)
      local self = setmetatable({}, DomRobot.API.Object.mt)
      self.client = client
      self.name = name
      return self
    end

  }

}

return DomRobot.API;
