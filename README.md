# inwx-lua

[Lua](http://www.lua.org/) client for the [DomRobot XML-RPC API](https://api.domrobot.com/).

The DomRobot API provides an interface for managing domain names, DNS, hosting and other internet services. Access is granted by [InterNetworX](https://www.inwx.com/) to their customers.

* Message format: [XML-RPC](http://www.xmlrpc.com/)
* Transport: HTTPS
* Authentication: Cookie through username/password login

## Compatibility

Code has been tested with Lua5.1, Lua5.2

## Dependencies

* [Lua XML-RPC](https://github.com/timn/lua-xmlrpc)
* [LuaSocket](https://github.com/diegonehab/luasocket)
* [LuaSec](https://github.com/brunoos/luasec)
 
You may need also openssl in order to get LuaSec working.
