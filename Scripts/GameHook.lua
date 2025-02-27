---@diagnostic disable:duplicate-set-field

---@class GameHook : ToolClass
GameHook = class()

sm.log.warning("[SURVIVAL QUESTS] START")

local description = sm.json.open("$CONTENT_DATA/description.json")
sm.SURVIVALQUESTSMODUUID = description.localId

gameHooked = gameHooked or false

local function attemptHook()
    sm.log.warning("[SURVIVAL QUESTS] TRY HOOK")
    if not gameHooked then
        sm.log.warning("SURVIVAL QUESTS] HOOK BEGIN")
        gameHooked = true

        dofile("$CONTENT_"..sm.SURVIVALQUESTSMODUUID.."/Scripts/vanilla_override.lua")
    end
end

oldBind = oldBind or sm.game.bindChatCommand
local function bindHook(command, params, callback, help)
    sm.log.warning("[SURVIVAL QUESTS] HOOK ATTEMPT FROM BIND COMMAND")
    attemptHook()

    return oldBind(command, params, callback, help)
end
sm.game.bindChatCommand = bindHook


oldStorageLoad = oldStorageLoad or sm.storage.load
function sm.storage.load(key)
    sm.log.warning("[SURVIVAL QUESTS] HOOK ATTEMPT FROM STORAGE LOAD")
    attemptHook()

    return oldStorageLoad(key)
end

oldSMExists = oldSMExists or sm.exists
function sm.exists( object )
    if type(object) == "table" then
        return true
    end

    return oldSMExists(object)
end