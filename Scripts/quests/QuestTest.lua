QuestTest = {}

function QuestTest.new()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST NEW")
    return {
        name = "quest_test",
        className = "QuestTest",
        clientPublicData = {
            progressString = "Hello im a test quest",
            title = "Epic Test Quest",
            isMainQuest = false
        }
    }
end

function QuestTest:destroy()
    print("destroy quest")
end

function QuestTest:server_onCreate()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST SERVER_ONCREATE")
    return {
        name = "quest_test",
        className = "QuestTest",
        sv = {
            stage = 1
        }
    }
end

function QuestTest:client_onDestroy()
    sm.log.warning("[SURVIVAL QUESTS] QUESTTEST CLIENT_ONDESTROY")
end