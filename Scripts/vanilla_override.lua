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
end

function QuestManager.sv_e_activateQuest( self, questName )
	local questUuid = self.sv.quests[questName]
	if questUuid ~= nil then
        if type(questUuid) == "string" then
            local questClass = _G[questUuid]
            self.sv.saved.activeQuests[questName] = questClass.new()
            self.sv.customQuestData[questName] = questClass.server_onCreate()
            sm.storage.save(sm.SURVIVALQUESTSMODUUID, self.sv.customQuestData)
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
            self.network:sendToClients("cl_CustomQuestCallback", { questName = questName, callback = "client_onDestroy" })
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
            self.network:sendToClients("cl_CustomQuestCallback", { questName = questName, callback = "client_onDestroy" })
        end
		self.sv.saved.activeQuests[questName] = nil
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self:sv_onEvent( QuestEvent.QuestCompleted, { questName = questName } )
	end
end

function QuestManager:sv_CustomQuestCallback(args)
    local quest = self.sv.saved.activeQuests[args.questName]
    _G[quest.className][args.callback](quest, args.params)
end

function QuestManager:cl_CustomQuestCallback(args)
    local quest = self.cl.activeQuests[args.questName]
    _G[quest.className][args.callback](quest, args.params)
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

oldInventoryChanges = oldInventoryChanges or SurvivalPlayer.server_onInventoryChanges
function SurvivalPlayer:server_onInventoryChanges( inventory, changes )
	--changes = { { uuid = Uuid, difference = integer, tool = Tool }, .. }
    oldInventoryChanges(self, inventory, changes)

    if changes.uuid == blk_scrapwood and changes.difference > 0 then
        
    end
end