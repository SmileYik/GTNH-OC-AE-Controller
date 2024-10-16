local component = require("component")
local me = component.me_interface

local mod = {}

local function getSimpleInfo(cpu)
    return {
        cpu = {},
        busy = cpu.busy,
        coprocessors = cpu.coprocessors,
        storage = cpu.storage,
        id = cpu.name
    }
end

local function simpleItemInfo(item)
    if item == nil then return nil end
    return {
        name = item.name,
        label = item.label,
        damage = item.damage,
        size = item.size,
        aspect = item.aspect
    }
end

local function simpleItemsInfo(items)
    if items == nil then return end
    for i, item in pairs(items) do
        items[i] = simpleItemInfo(item)
    end
end

local function removeEmptyItem(items)
    if items == nil then return nil end

    local newOne = {}
    for _, item in pairs(items) do
        if item.size ~= nil and item.size ~= 0 or item.amount ~= nil and item.amount ~= 0 then
            table.insert(newOne, simpleItemInfo(item))
        end
    end
    return newOne
end

local function getDetailInfo(cpu)
    local sub = cpu.cpu
    local result = {
        activeItems = removeEmptyItem(sub.activeItems()),
        finalOutput = sub.finalOutput(),
        active = sub.isActive(),
        busy = sub.isBusy(),
        pendingItems = removeEmptyItem(sub.pendingItems()),
        storedItems = removeEmptyItem(sub.storedItems())
    }
    return result
end

function mod.getCpuList(detail)
    local cpus = me.getCpus()
    if cpus == nil then return {} end
    local result = {}
    for _, cpu in pairs(cpus) do
        local simple = getSimpleInfo(cpu)
        if detail then simple.cpu = getDetailInfo(cpu) end
        table.insert(result, simple)
    end
    return result
end

function mod.getCpuDetail(cpuName)
    local cpus = me.getCpus()
    if cpus == nil then return nil end
    for _, cpu in pairs(cpus) do
        if cpu.name == cpuName then
            local result = getSimpleInfo(cpu)
            result.cpu = getDetailInfo(cpu)
            return result
        end
    end
    return nil
end

return mod
