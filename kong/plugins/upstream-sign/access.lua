local _M = {}
local hmac_sha1 = ngx.hmac_sha1
local encode_base64 = ngx.encode_base64
local openssl_hmac = require "resty.openssl.hmac"
local kong = kong
local fmt = string.format
local sha256 = require "resty.sha256"
local resty_md5 = require "resty.md5"
local str = require "resty.string"


local function gen_md5(params)
    local md5 = resty_md5:new()
    ok = md5:update(params)
    if not ok then
        ngx.log("failed to add data")
        return
    end
    return ok
end


local function gen_timestamp()
    return os.time(os.date("!*t"))*1000
end


local function gen_digest(conf)
     headers= kong.request.get_headers()


     for key, val in pairs(headers) do
         if type(val) == "table" then
             ngx.log(ngx.NOTICE, key, ": ", table.concat(val, ", "))
         else
             ngx.log(ngx.NOTICE, key, ": ", val)
         end
     end
     ngx.req.set_header("md5", gen_md5(headers))
end

local function sign_param(conf)
    gen_digest(conf)
    -- local date = os.date("!%a, %d %b %Y %H:%M:%S GMT")
    -- local encodedSignature   = ngx.encode_base64(hmac_sha1_binary("secret", "date: " .. date))
    -- local hmacAuth = [[hmac username="bob",algorithm="hmac-sha1",]]
    --   .. [[headers="date",signature="]] .. encodedSignature .. [["]]
end

function _M.execute(conf)
    sign_param(conf)
end

return _M