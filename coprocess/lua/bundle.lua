local cjson = require "cjson"

-- Make the current object accessible for helpers.
object = nil

-- This will be generated by the bundle (request.lua):
local request = {}
local session = {}

-- Based on: https://github.com/openresty/lua-nginx-module#ngxreqset_body_file

function request.start_time()
end

function request.http_version()
end

function request.get_headers()
  return object['request']['headers']
end

function request.set_header(key, value)
  if object['request']['set_headers'] == nil then
    object['request']['set_headers'] = {}
  end
  object['request']['set_headers'][key] = value
end

function request.clear_header(key)
  if object['request']['delete_headers'] == nil then
    object['request']['delete_headers'] = {}
  end
  object['request']['delete_headers'] = {key}
end

tyk = {
  -- req = {},
  -- req=require("coprocess.lua.tyk.request"),
  req = request,
  session = session,
  header=nil
}

function dispatch(raw_object)
  object = cjson.decode(raw_object)
  raw_new_object = nil

  -- Environment reference to hook.
  hook_name = object['hook_name']
  hook_f = _G[hook_name]
  is_custom_key_auth = false

  -- Set a flag if this is a custom key auth hook.
  if object['hook_type'] == 4 then
    is_custom_key_auth = true
  end

  -- Call the hook and return a serialized version of the modified object.
  if hook_f then
    local new_request, new_session, metadata

    -- tyk.header = object['request']['headers']

    if custom_key_auth then
      new_request, new_session, metadata = hook_f(object['request'], object['session'], object['metadata'], object['spec'])
    else
      new_request, new_session = hook_f(object['request'], object['session'], object['spec'])
    end

    -- Modify the CP object.
    object['request'] = new_request
    object['session'] = new_session
    object['metadata'] = metadata

    raw_new_object = cjson.encode(object)

    -- return raw_new_object, #raw_new_object

  -- Return the original object and print an error.
  else
    return raw_object, #raw_object
  end

  return raw_new_object, #raw_new_object
end

function dispatch_event(raw_event)
  print("dispatch_event:", raw_event)
end
