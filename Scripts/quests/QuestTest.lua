QuestTest = {}

function QuestTest.new()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST NEW")
    return {
        name = "quest_test",
        className = "QuestTest",
        clientPublicData = {
            progressString = "Pick up some scrap wood",
            title = "Epic Test Quest",
            isMainQuest = false
        }
    }
end

function QuestTest.sv_new()
    return {
        name = "quest_test",
        className = "QuestTest",
        sv = {
            stage = 1
        }
    }
end



function QuestTest:server_onCreate()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST SERVER_ONCREATE")

    QuestManager.Sv_SubscribeEvent( QuestEvent.InventoryChanges, self.name, "sv_onInventoryUpdate" )
    sm.event.sendToScriptableObject(g_questManager.scriptableObject, "sv_CustomQuestClientDataUpdate", { questName = self.name, data = { stage = self.sv.stage } })
end

function QuestTest:server_onDestroy()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST SERVER_ONDESTROY")
end

function QuestTest:server_onFixedUpdate(dt)
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST SERVER_ONFIXEDUPDATE")
end

function QuestTest:sv_onInventoryUpdate(args)
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST ONINVENTORYUPDATE")

    local scrapWoodChange = FindInventoryChange(args.params.changes, blk_scrapwood)
    if (self.sv.stage == 1 or self.sv.stage == 3) and scrapWoodChange > 0 then
        self.sv.stage = self.sv.stage + 1
    elseif self.sv.stage == 2 and scrapWoodChange < 0 then
        self.sv.stage = self.sv.stage + 1
    end

    sm.event.sendToScriptableObject(g_questManager.scriptableObject, "sv_CustomQuestSaveAndUpdate", { questName = self.name, data = { stage = self.sv.stage } })

    if self.sv.stage == 4 then
        QuestManager.Sv_CompleteQuest(self.name)
    end
end



function QuestTest:client_onClientDataUpdate(data, channel)
    local progressStrings = {
        [2] = "Drop some scrap wood",
        [3] = "Pick up some scrap wood again",
    }
    self.clientPublicData.progressString = progressStrings[data.stage]
end

function QuestTest:client_onDestroy()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST CLIENT_ONDESTROY")
end