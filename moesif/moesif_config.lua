local _M = {}

local function isempty(s)
    return s == nil or s == '' or s == "nil"
end

function _M.getDefaultConfig()
    -- Set Default values.
    local config = {}
    if isempty(ngx.var.moesif_application_id) then
        config["moesif_application_id"] = ""
    else
        config["moesif_application_id"] = ngx.var.moesif_application_id
    end

    if isempty(ngx.var.disable_transaction_id) then
        config["disable_transaction_id"] = false
    else
        config["disable_transaction_id"] = ngx.var.disable_transaction_id
    end

    if isempty(ngx.var.api_endpoint) then
        config["api_endpoint"] = "https://api.moesif.net"
    else
        config["api_endpoint"] = ngx.var.api_endpoint
    end

    if isempty(ngx.var.timeout) then
        config["timeout"] = 1000
    else
        config["timeout"] = ngx.var.timeout
    end

    if isempty(ngx.var.connect_timeout) then
        config["connect_timeout"] = 1000
    else
        config["connect_timeout"] = ngx.var.connect_timeout
    end

    if isempty(ngx.var.send_timeout) then
        config["send_timeout"] = 2000
    else
        config["send_timeout"] = ngx.var.send_timeout
    end

    if isempty(ngx.var.keepalive) then
        config["keepalive"] = 5000
    else
        config["keepalive"] = ngx.var.keepalive
    end

    if isempty(ngx.var.disable_capture_request_body) then
        config["disable_capture_request_body"] = false
    else
        config["disable_capture_request_body"] = ngx.var.disable_capture_request_body
    end

    if isempty(ngx.var.disable_capture_response_body) then
        config["disable_capture_response_body"] = false
    else
        config["disable_capture_response_body"] = ngx.var.disable_capture_response_body
    end

    if isempty(ngx.var.request_masks) then
        config["request_masks"] = ""
    else
        config["request_masks"] = ngx.var.request_masks
    end

    if isempty(ngx.var.request_body_masks) then
        config["request_body_masks"] = ""
    else
        config["request_body_masks"] = ngx.var.request_body_masks
    end

    if isempty(ngx.var.request_header_masks) then
        config["request_header_masks"] = ""
    else
        config["request_header_masks"] = ngx.var.request_header_masks
    end

    if isempty(ngx.var.response_masks) then
        config["response_masks"] = ""
    else
        config["response_masks"] = ngx.var.response_masks
    end

    if isempty(ngx.var.response_body_masks) then
        config["response_body_masks"] = ""
    else
        config["response_body_masks"] = ngx.var.response_body_masks
    end

    if isempty(ngx.var.response_header_masks) then
        config["response_header_masks"] = ""
    else
        config["response_header_masks"] = ngx.var.response_header_masks
    end

    if isempty(ngx.var.batch_size) then
        config["batch_size"] = 200
    else
        config["batch_size"] = ngx.var.batch_size
    end

    if isempty(ngx.var.debug) then
        config["debug"] = false
    else
        config["debug"] = ngx.var.debug
    end

    if isempty(ngx.var.batch_max_time) then
        config["batch_max_time"] = 2
    else
        config["batch_max_time"] = ngx.var.batch_max_time
    end

    if isempty(ngx.var.max_callback_time_spent) then
        config["max_callback_time_spent"] = 2000
    else
        config["max_callback_time_spent"] = ngx.var.max_callback_time_spent
    end

    if isempty(ngx.var.disable_gzip_payload_decompression) then
        config["disable_gzip_payload_decompression"] = false
    else
        config["disable_gzip_payload_decompression"] = ngx.var.disable_gzip_payload_decompression
    end

    if isempty(ngx.var.queue_scheduled_time) then
        config["queue_scheduled_time"] = os.time{year=1970, month=1, day=1, hour=0}
    else
        config["queue_scheduled_time"] = ngx.var.queue_scheduled_time
    end

    if isempty(ngx.var.max_body_size_limit) then
        config["max_body_size_limit"] = 100000
    else
        config["max_body_size_limit"] = ngx.var.max_body_size_limit
    end

    if isempty(ngx.var.authorization_header_name) then
        config["authorization_header_name"] = "authorization"
    else
        config["authorization_header_name"] = ngx.var.authorization_header_name
    end

    if isempty(ngx.var.authorization_user_id_field) then
        config["authorization_user_id_field"] = "sub"
    else
        config["authorization_user_id_field"] = ngx.var.authorization_user_id_field
    end
    return config
end

return _M
