-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------
local resty_md5 = require "resty.md5"
local str = require "resty.string"



local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}



-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.



---[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()

  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]



--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'certificate' handler")

end --]]



--[[ runs in the 'rewrite_by_lua_block'
-- IMPORTANT: during the `rewrite` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'rewrite' handler")

end --]]

local function gen_timestamp()
    return os.time(os.date("!*t"))*1000
end


local function gen_md5(sign_str)
  local md5 = resty_md5:new()
  local ok = md5:update(sign_str)
  if not ok then
      ngx.log("failed to add data")
      return
  end
  local digest = md5:final()
  return string.upper(str.to_hex(digest))

end


local function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end


local function gen_digest(conf)
     -- headers = kong.request.get_headers()
     -- c7b5a9f76c4825c45cf845f179a93b15app_key28439329fieldstid,type,status,payment,orders,rx_audit_statusformatjsonmethodtaobao.trades.sold.getsession6102b27beeddc94be349c92a87d3e72889f1ebf106b24942206381427828sign_methodmd5timestamp1600962986224v2.0c7b5a9f76c4825c45cf845f179a93b15'
   local params = {      
        app_key = "XXXXX",
        fields = "tid,type,status,payment,orders,rx_audit_status",
        format = "json",
        method = "taobao.trades.sold.get",
        sign_method = "md5",
        session = "XXXXXXXX",       
        timestamp = gen_timestamp(),
        v = "2.0"
    }
   -- table.sort(headers)
   local secret = "c7b5a9f76c4825c45cf845f179a93b15"
   local tobe_signed = secret

   for key, val in pairsByKeys(params) do
      tobe_signed = tobe_signed..key..val
   end
   -- local tobe_signed = 'c7b5a9f76c4825c45cf845f179a93b15app_key28439329fieldstid,type,status,payment,orders,rx_audit_statusformatjsonmethodtaobao.trades.sold.getsession6102b27beeddc94be349c92a87d3e72889f1ebf106b24942206381427828sign_methodmd5timestamp1600962986224v2.0c7b5a9f76c4825c45cf845f179a93b15'
   tobe_signed = tobe_signed..secret
   local sign = gen_md5(tobe_signed)
   params["sign"] =  sign

   ngx.req.set_uri_args(params)
   ngx.req.set_header("tobe_signed:", tobe_signed)
   ngx.req.set_header("sign:", sign)

end


---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  -- your custom code here
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!
  ngx.req.set_header(plugin_conf.request_header, "this is on a request")
  -- ngx.req.set_header("md5", "this is a md5")

  gen_digest(plugin_conf)

end --]]


---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)

  -- your custom code here, for example;
  ngx.header[plugin_conf.response_header] = "this is on the response"

end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'body_filter' handler")

end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'log' handler")

end --]]


-- return our plugin object
return plugin
