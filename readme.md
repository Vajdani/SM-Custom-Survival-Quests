# Survival Quests Injector for Scrap Mechanic
This mod provides a way of injecting custom quests into Scrap Mechanic's Survival gamemode, or any custom game that also uses Survival's quest system.

# How to add a quest
1. Add a new entry to the `questList` table in `Scripts/vanilla_override.lua`, which contains the quest's id, and it's script/class name.
```lua
local questList = {
    --Quest name, quest script/class name.
    { "quest_myQuest", "MyQuest" }
}
```
2. Make a new script in `Scripts/quests/`, with the script name you used in **step 1**.\
Here is an example for `MyQuest.lua`:
```lua
MyQuest = {}

function MyQuest.new()
    return {
        name = "quest_myQuest", --The name of your quest
        className = "MyQuest", --The class/script name
        clientPublicData = {
            --These values control how the quest is displayed on the tracker
            --on the side of the screen.
            progressString = "Hi! This is my first quest! Pick up some scrap wood to progress the quest!", --The description of current task of the quest.
            title = "My first quest", --The quest's name.
            isMainQuest = false --Whether it's a quest in the main story.
        }
    }
end

function MyQuest.sv_new()
    return {
        name = "quest_myQuest", --The name of your quest
        className = "MyQuest", --The class/script name
        sv = {
            stage = 1 --The current task stage of the quest
        }
    }
end



--Called when the quest is created on the server.
function MyQuest:server_onCreate()
    print("MyQuest server_onCreate")

    --Subscribe to the player inventory update event.
    QuestManager.Sv_SubscribeEvent( QuestEvent.InventoryChanges, self.name, "sv_onInventoryUpdate" )

    --Send the quest data to the client.
    sm.event.sendToScriptableObject(
        g_questManager.scriptableObject,
        "sv_CustomQuestClientDataUpdate",
        {
            questName = self.name, --The name of this quest, this will identify it in the backend.
            data = { stage = self.sv.stage } --The data that will be sent.
        }
    )
end

--Called when the quest is destroyed on the server.
function MyQuest:server_onDestroy()
    print("MyQuest server_onDestroy")
end

--Called 40 times per second on the server.
function MyQuest:server_onFixedUpdate(dt)
    print("MyQuest server_onFixedUpdate")
end

--Called when a player's inventory is changed, we subscribed to the event in "server_onCreate".
function MyQuest:sv_onInventoryUpdate(args)
    print("MyQuest sv_onInventoryUpdate")

    --Find any scrap wood changes in the inventory
    local scrapWoodChange = FindInventoryChange(args.params.changes, blk_scrapwood)

    --Are we in the "pick up wood" stages, and has the player picked up scrap wood?
    if (self.sv.stage == 1 or self.sv.stage == 3) and scrapWoodChange > 0 then
        --Progress to the next stage.
        self.sv.stage = self.sv.stage + 1
    --Are we in the "drop wood" stage, and has the player spent any wood?
    elseif self.sv.stage == 2 and scrapWoodChange < 0 then
        --Progress to the next stage.
        self.sv.stage = self.sv.stage + 1
    end

    --Save the stage and update the clients.
    sm.event.sendToScriptableObject(
        g_questManager.scriptableObject,
        "sv_CustomQuestSaveAndUpdate",
        {
            questName = self.name, --The name of this quest, this will identify it in the backend.
            data = { stage = self.sv.stage } --The data that will be sent.
        }
    )

    --Finish the quest if all stages have been completed.
    if self.sv.stage == 4 then
        QuestManager.Sv_CompleteQuest(self.name)
    end
end



--Called on the client when "sv_CustomQuestSaveAndUpdate" and "sv_CustomQuestClientDataUpdate" are used.
function MyQuest:client_onClientDataUpdate(data, channel)
    local progressStrings = {
        [2] = "Drop some scrap wood to progress the quest!", --Description of the second stage.
        [3] = "Pick up some scrap wood again to progress the quest!", --Description of the third stage.
    }
    self.clientPublicData.progressString = progressStrings[data.stage] --Update the GUI.
end

--Called when the quest is destroyed on the client.
function MyQuest:client_onDestroy()
    print("MyQuest client_onDestroy")
end
```
3. Done! You have added your quest to the game. Now you just have to activate it from somewhere.

# Forking
If you wish to use this project as a base for your own:
1. Rename `description_template.json` to `description.json`, and open the file.\
Change the `localId` property to a new UUID that you generated(For example, on [this](https://www.uuidgenerator.net/version4) website), and give the mod a name and a description.
2. Change `GameHook` autoTool's UUID in `Tools/DataBase/ToolSets/tools.toolset` to a new UUID.