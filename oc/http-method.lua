local net = require("internet")
local json = require("json")
local config = require("config")

local mod = {
    TASK = {
        REQUEST_FAILED = "Failed to request task",
        NO_TASK = "No task",
        NO_TARGET_FUNCTION = "No target function",
        SUCCESS = "Finshied task",
        RUN_TASK_ERROR = "Something is wrong in task function"
    }
}
local url
local functions
local lastestTaskDate = nil

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
    for chunk in handle do reply = reply .. chunk end
    local code, response, responseHeader = handle.response()
    if code == 200 then
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
    local result, reply, code, response, responseHeader = pcall(require, path, "GET", header, nil)
    if not result then code = 400 end
    return reply, code, response, responseHeader
end

function mod.post(path, header, body)
    local result, reply, code, response, responseHeader = pcall(require, path, "POST", header, body)
    if not result then code = 400 end
    return reply, code, response, responseHeader
end

function mod.delete(path, header)
    local result, reply, code, response, responseHeader = pcall(require, path, "DELETE", header, nil)
    if not result then code = 400 end
    return reply, code, response, responseHeader
end

function mod.put(path, header, body)
    local result, reply, code, response, responseHeader = pcall(require, path, "PUT", header, body)
    if not result then code = 400 end
    return reply, code, response, responseHeader
end

function mod.nextTask(taskPath)
    local res, code = mod.get(taskPath)
    if code ~= 200 then return nil end
    if res == nil or res.method == nil then return nil end
    mod.put(taskPath, {}, {des = "ok"})
    return res
end

function mod.executeNextTask(taskPath)
    local header = nil
    if lastestTaskDate ~= nil then
        header = {["If-Modified-Since"] = lastestTaskDate}
    end
    local res, code, _, rHeader = mod.get(taskPath, header)
    if code == 304 then return mod.TASK.NO_TASK, "304" end
    if code ~= 200 then return mod.TASK.REQUEST_FAILED, "http request failed" end
    -- res = {method = "", data = {}}

    if rHeader ~= nil and type(rHeader) == "table" then lastestTaskDate = rHeader["Date"][1] end
    if res == nil or res.method == nil then return mod.TASK.NO_TASK, "no task" end
    if functions == nil or functions[res.method] == nil then return mod.TASK.NO_TARGET_FUNCTION, res.method end
    mod.put(taskPath, {}, {des = "ok"})

    local r, des, result = pcall(functions[res.method], res.data)
    if not r then
        mod.put(taskPath, {}, {des = "Error: " .. des})
        return mod.TASK.RUN_TASK_ERROR, res.method .. ": " .. des
    end

    if des == nil then des = "ok" end
    mod.put(taskPath, {}, {des = des, result = result})
    return mod.TASK.SUCCESS, "success"
end

return mod
