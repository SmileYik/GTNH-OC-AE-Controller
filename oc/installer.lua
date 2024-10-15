local NEED_DOWNLOAD = {
    ["config"] = "https://ocae.smileyik.eu.org/oc/config.lua",
    ["cpu"] = "https://ocae.smileyik.eu.org/oc/cpu.lua",
    ["http-method"] = "https://ocae.smileyik.eu.org/oc/http-method.lua",
    ["json"] = "https://ocae.smileyik.eu.org/oc/json.lua",
    ["main"] = "https://ocae.smileyik.eu.org/oc/main.lua"
}

local function checkInternetCard()
    -- check internet card
    local component = require("component")
    if component == nil or component.internet == nil then
        return
    end
end

if not pcall(checkInternetCard) then
    print("you need an internet card to continue!")
    return
end

local pwd = os.getenv().PWD
local targetDirectory = "oc-ae"

local args = { ... }

for i in pairs(args) do
    if args[i] == "--target-directory" or args[i] == "-td" then
        i = i + 1
        if args[i] ~= nil and type(args[i]) == "string" then
            targetDirectory = args[i]
        end
    end
end

if string.find(targetDirectory, "/") ~= 1 then
    targetDirectory = pwd .. "/" .. targetDirectory
end

print("The program will install to " .. targetDirectory)

local createdDirs = {}
for filePath, url in pairs(NEED_DOWNLOAD) do
    local targetFile = targetDirectory .. "/" .. filePath .. ".lua"
    local i = string.len(targetFile) - string.find(string.reverse(targetFile), "/")
    local parentDir = string.sub(targetFile, 1, i)
    if nil == createdDirs[parentDir] then
        os.execute("mkdir " .. parentDir)
        createdDirs[parentDir] = true
    end
    os.execute("wget " .. url .. " " .. targetFile)
end


print("create a quick link to /home directory")
os.execute("echo \"os.execute(\\\"cd '" .. targetDirectory .. "' && ./main.lua\\\")\" > /home/oc-ae.lua")
print("install finished")
