sm.log.warning("[SURVIVAL QUESTS] VANILLA OVERRIDE START")

local questList = {
    { "quest_test", "QuestTest" }
}
local questScriptPath = "$CONTENT_"..sm.SURVIVALQUESTSMODUUID.."/Scripts/quests/%s.lua"

oldQuestManagerServerCreate = oldQuestManagerServerCreate or QuestManager.server_onCreate
function QuestManager:server_onCreate()
    oldQuestManagerServerCreate(self)

    for k, v in pairs(questList) do
        local class = v[2]
        dofile(questScriptPath:format(class))
        self.sv.quests[v[1]] = class
    end

    self.sv.customQuestData = sm.storage.load(sm.SURVIVALQUESTSMODUUID) or {}
    for name, questSelf in pairs(self.sv.customQuestData) do
        if self.sv.saved.activeQuests[name] then
            local func = _G[questSelf.className]["server_onCreate"]
            if func then
                func(questSelf)
            end
        end
    end
end

function QuestManager.sv_e_activateQuest( self, questName )
	local questUuid = self.sv.quests[questName]
	if questUuid ~= nil then
        if type(questUuid) == "string" then
            local questClass = _G[questUuid]
            self.sv.saved.activeQuests[questName] = questClass.new()

            local questSelf = questClass.sv_new()
            local func = questClass["server_onCreate"]
            if func then
                func(questSelf)
            end

            self.sv.customQuestData[questName] = questSelf

            self:sv_CustomQuestSave()
        else
            self.sv.saved.activeQuests[questName] = sm.scriptableObject.createScriptableObject( questUuid )
        end

		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self:sv_onEvent( QuestEvent.QuestActivated, { questName = questName } )
	else
		sm.log.error( questName .. " did not exist!" )
	end
end

function QuestManager.sv_e_abandonQuest( self, questName )
	local quest = self.sv.saved.activeQuests[questName]
	if quest then
		QuestManager.Sv_UnsubscribeAllEvents( quest )
        if self.sv.saved.activeQuests[questName].destroy then
            self.sv.saved.activeQuests[questName]:destroy()
        else
            self:sv_CustomQuestCallback({ questName = questName, callback = "server_onDestroy" })
            self.network:sendToClients("cl_CustomQuestCallback", { questName = questName, callback = "client_onDestroy" })
            self.sv.customQuestData[questName] = nil
            self:sv_CustomQuestSave()
        end
		self.sv.saved.activeQuests[questName] = nil
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self:sv_onEvent( QuestEvent.QuestAbandoned, { questName = questName } )
	end
end

function QuestManager.sv_e_completeQuest( self, questName )
	local completedQuest = self.sv.saved.activeQuests[questName]
	if completedQuest then
		self.network:sendToClients( "cl_n_questCompleted", questName )
		self.sv.saved.completedQuests[questName] = true
        if self.sv.saved.activeQuests[questName].destroy then
            self.sv.saved.activeQuests[questName]:destroy()
        else
            self:sv_CustomQuestCallback({ questName = questName, callback = "server_onDestroy" })
            self.network:sendToClients("cl_CustomQuestCallback", { questName = questName, callback = "client_onDestroy" })
            self.sv.customQuestData[questName] = nil
            self:sv_CustomQuestSave()
        end
		self.sv.saved.activeQuests[questName] = nil
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self:sv_onEvent( QuestEvent.QuestCompleted, { questName = questName } )
	end
end

function QuestManager:sv_CustomQuestCallback(args)
    local name = args.questName
    local quest = self.sv.saved.activeQuests[name]
    if not quest then return end

    _G[quest.className][args.callback](self.sv.customQuestData[name], args.params)
end

function QuestManager.sv_onEvent( self, event, params )
	--print( "QuestManager - Event:", event, "params:", params )
	--print( "Subscribers:", self.sv.eventSubs[event] )
	if self.sv.eventSubs[event] ~= nil then
		for _, subCallback in ipairs( self.sv.eventSubs[event] ) do
			local sub = subCallback[1]
			local callbackName = subCallback[2]
			local data = { event = event, params = params }

            local t = type( sub )
            if t == "string" then
                self:sv_CustomQuestCallback({ questName = sub, callback = callbackName, params = data })
                return
            end

			if not sm.exists( sub ) then
				sm.log.warning( "Tried to send callback to subscriber which does not exist: " .. tostring( sub ) )
				return
			end
			if t == "Harvestable" then
				sm.event.sendToHarvestable( sub, callbackName, data )
			elseif t == "ScriptableObject" then
				sm.event.sendToScriptableObject( sub, callbackName, data )
			elseif t == "Character" then
				sm.event.sendToCharacter( sub, callbackName, data )
			elseif t == "Tool" then
				sm.event.sendToTool( sub, callbackName, data )
			else
				sm.log.error( "Tried to send event to non-supported type in QuestCallbackHelper" )
			end
		end
	end
end

if not tryGetQuestManagerServerUpdate then
    oldQuestManagerServerUpdate = QuestManager.server_onFixedUpdate
    tryGetQuestManagerServerUpdate = true
end

function QuestManager:server_onFixedUpdate(dt)
    if oldQuestManagerServerUpdate then
        oldQuestManagerServerUpdate(self, dt)
    end

    for name, questSelf in pairs(self.sv.customQuestData) do
        if self.sv.saved.activeQuests[name] then
            local func = _G[questSelf.className]["server_onFixedUpdate"]
            if func then
                func(questSelf, dt)
            end
        end
    end
end


function QuestManager:sv_CustomQuestSaveAndUpdate(args)
    sm.storage.save(sm.SURVIVALQUESTSMODUUID, self.sv.customQuestData)
    self:sv_CustomQuestClientDataUpdate(args)
end

function QuestManager:sv_CustomQuestSave()
    sm.storage.save(sm.SURVIVALQUESTSMODUUID, self.sv.customQuestData)
end

function QuestManager:sv_CustomQuestClientDataUpdate(args)
    self.network:sendToClients("cl_CustomQuestClientDataUpdate", args)
end



function QuestManager:cl_CustomQuestCallback(args)
    local quest = self.cl.activeQuests[args.questName]
    if not quest then return end

    _G[quest.className][args.callback](quest, args.params)
end

function QuestManager:cl_CustomQuestClientDataUpdate(args)
    local quest = self.cl.activeQuests[args.questName]
    if not quest then return end

    local func = _G[quest.className]["client_onClientDataUpdate"]
    if func then
        func(quest, args.data, args.channel)
    end
	self.cl.questTrackerDirty = true
end

function QuestManager.client_onClientDataUpdate( self, data )
    for k, v in pairs(data.activeQuests) do
        if not self.cl.activeQuests[k] then
            self.cl.activeQuests[k] = v
        end
    end

	self.cl.completedQuests = data.completedQuests
	self.cl.questTrackerDirty = true
end



if not SurvivalPlayer then
    dofile "$SURVIVAL_DATA/Scripts/game/SurvivalPlayer.lua"
end

function SurvivalPlayer:client_onReload()
    sm.log.warning("hdkjhfkjdhfkj")
    self.network:sendToServer("sv_test")

    return true
end

function SurvivalPlayer:sv_test()
    g_questManager.Sv_TryActivateQuest("quest_test")
end