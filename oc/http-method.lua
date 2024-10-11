local net = require("internet")
local json = require("json")
local config = require("config")

local mod = {
    TASK = {
        RETASK_FAILED = "Failed to request task",
        NO_TASK = "No task",
        NO_TARGET_FUNCTION = "No target function",
        SUCCESS = "Finshied task"
    }
}
local url
local functions

local function require(path, method, header, body)
    path = url .. path
    if header == nil then header = {} end
    header["Content-Type"] = "application/json"
    header["ocaetoken"] = config.token

    if body ~= nil then
        if type(body) ~= "string" then
            body = json.encode(body)
        end
    end

    local reply = ""
    local handle = net.request(path, body, header, method)

    local code, response, responseHeader = handle.response()
    if code == 200 then
        for chunk in handle do reply = reply .. chunk end
        reply = json.decode(reply)
    end

    local mt = getmetatable(handle.close)
    mt.__call()

    return reply, code, response, responseHeader
end

function mod.init(baseUrl, funcs)
    url = baseUrl
    functions = funcs
end

function mod.get(path, header)
    return require(path, "GET", header, nil)
end

function mod.post(path, header, body)
    return require(path, "POST", header, body)
end

function mod.delete(path, header)
    return require(path, "DELETE", header, nil)
end

function mod.put(path, header, body)
    return require(path, "PUT", header, body)
end

function mod.nextTask(taskPath)
    local res, code = mod.get(taskPath)
    if code ~= 200 then return nil end
    if res == nil or res.method == nil then return nil end
    mod.put(taskPath, {}, {des = "finished"})
    return res
end

function mod.executeNextTask(taskPath)
    local res, code = mod.get(taskPath)
    if code ~= 200 then return mod.TASK.RETASK_FAILED, "http request failed" end
    -- res = {method = "", data = {}}
    if res == nil or res.method == nil then return mod.TASK.NO_TASK, "no task" end
    if functions == nil or functions[res.method] == nil then return mod.TASK.NO_TARGET_FUNCTION, res.method end
    mod.put(taskPath, {}, {des = "all task finished"})
    local des, result = functions[res.method](res.data)
    if des == nil then des = "all task finshed" end
    mod.put(taskPath, {}, {des = des, result = result})
    return mod.TASK.SUCCESS, "success"
end

return mod
