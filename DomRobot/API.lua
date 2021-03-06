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

  -- DomRobot API URL.
  url = function(host)
    -- For socket.http, it is important to explicitely mention the port
    return "https://" .. host .. ":443/xmlrpc/"
  end,

  -- DomRobot API functions have the form "object.method".
  methodName = function(object,method)
    return object .. "." .. method
  end,

  -- Format server error code + message.
  failure = function (object,method,response)
    return "Server replied to " .. DomRobot.API.methodName(object,method) ..  ": " ..
      tostring(response.code) .. " - " .. response.msg
  end,

  -- Authentication pattern.
  authMatch = function(cookie)
    -- cookie looks like: "domrobot=5599118952f13f5a00a47f3f2fa7b1a5; path=/"
    return cookie:match("^domrobot=[^;]+")
  end,

  -- Request headers.
  headers = function(contentLength,authCookie)
    local h = {
      ["content-type"] = "text/xml; charset=utf-8"
      -- add custom headers here
    }
    if contentLength then h["content-length"] = contentLength end
    if authCookie then h["cookie"] = authCookie end
    return h
  end,

  -- Whether or not a result code indicates a successful request.
  successful = function(res)
    -- See https://www.inwx.com/de/help/apidoc/f/ch04.html for possible result codes.
    return res.code >= 1000 and res.code < 2000
  end,

  -- Member functions
  prototype = {

    login = function(s,user,pass,lang)
      return s.client:login(user,pass,lang)
    end,

    persistentLogin = function(s,file,user,pass,lang)
      return s.client:persistentLogin(file,user,pass,lang)
    end

  },

  -- metatable:
  -- Any unknown symbol is treated as API object namespace, providing a set of
  -- functions and thus 'api.object:method(args)' calls.
  mt = {
    __index = function(table,key)
      if DomRobot.API.prototype[key] then return DomRobot.API.prototype[key] end
      return DomRobot.API.Object.new(table.client,key) -- assume object namespace
    end
  },
  
  -- DomRobot.API c'tor
  new = function(client)
    local self = setmetatable({}, DomRobot.API.mt)
    self.client = client
  	return self
  end,

  -- DomRobot API object namespace, providing methods.
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

setmetatable(DomRobot.API, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

return DomRobot.API;
