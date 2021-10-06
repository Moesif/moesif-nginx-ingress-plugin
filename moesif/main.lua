local req_get_method = ngx.req.get_method
local req_start_time = ngx.req.start_time
local ngx_now = ngx.now
local ngx_log = ngx.log
local moesif_config = require("plugins.moesif.moesif_config")
local moesif_ser = require("plugins.moesif.moesif_ser")
local log = require("plugins.moesif.log")
local url = require "plugins.moesif.socket.url"
local cjson = require "cjson"
local cjson_safe = require "cjson.safe"

local _M = {}

function _M.rewrite()
    local read_request_body = require("plugins.moesif.read_req_body")
    read_request_body.read_request_body()
end

function _M.header_filter()
    ngx.var.moesif_user_id = ngx.req.get_headers()[ngx.var.moesif_user_id_header]
    ngx.var.moesif_company_id = ngx.req.get_headers()[ngx.var.moesif_company_id_header]
end

function _M.body_filter()
    local read_response_body = require("plugins.moesif.read_res_body")
    read_response_body.read_response_body()
end

function _M.log()
    local config = moesif_config.getDefaultConfig()

    if config.moesif_application_id == nil or config.moesif_application_id == '' or config.moesif_application_id == "nil" then 
        ngx.log(ngx.ERR, "[moesif] Please provide the Moesif Application Id");
    else
        local message = moesif_ser.prepare_message(config)
        -- Execute/Log message
        log.execute(config, message, "moesif-nginx-ingress/0.0.1", config.debug)
    end
end


return _M