local helpers = require "spec.helpers"
local cjson = require "cjson"


local PLUGIN_NAME = "upstream-sign"


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "gw.api.taobao.com" }
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    describe("request", function()
      it("get signed parameters", function()
        local r = client:send {
              method  = "GET",
              -- path    = "/router/rest",
              headers = {
                ["Host"]         = "gw.api.taobao.com"
              }
            }
        ngx.say("Hello there")
        ngx.say(r.body)
        -- validate that the request succeeded, response status 200
        -- assert.response(r).has.status(200)
        local body = assert.response(r).has.status(200)
        local json = cjson.decode(body)
        print(json)


        local sign = assert.request(r).has.queryparam("sign")
        print("sign param:"..sign)
        -- now check the request (as echoed by mockbin) to have the header
        local tobe_signed = assert.request(r).has.header("tobe_signed")
        print("tobe_signed:"..tobe_signed)

        local md5_value = assert.request(r).has.header("sign")
        print("md5_value:"..md5_value)
        -- validate the value of that header
      end)
    end)



    -- describe("response", function()
    --   it("gets a 'bye-world' header", function()
    --     local r = client:get("/request", {
    --       headers = {
    --         host = "test1.com"
    --       }
    --     })
    --     -- validate that the request succeeded, response status 200
    --     assert.response(r).has.status(200)
    --     -- now check the response to have the header
    --     local header_value = assert.response(r).has.header("bye-world")
    --     -- validate the value of that header
    --     assert.equal("this is on the response", header_value)
    --   end)
    -- end)

  end)
end
