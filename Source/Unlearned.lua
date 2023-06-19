local addonName, addon = ...

local db = addon.TitleDB

addon.unknownTitles = {}
addon.unobtainableTitles = {}

function addon.UpdateDB()
    wipe(addon.unknownTitles)
    wipe(addon.unobtainableTitles)
    for id, data in ipairs(db) do
        if  (not data.temporary) and 
            (not IsTitleKnown(id)) and 
            ((data.faction == "Both") or (data.faction == UnitFactionGroup("player"))) and 
            ((not data.race) or (data.race == select(2,UnitRace("player")))) and
            ((not data.class) or (data.class == select(2,UnitClass("player")))) and
            ((not data.bodyType) or ((data.bodyType == "Body 1") and UnitSex("player") == 2) or ((data.bodyType == "Body 2") and UnitSex("player") == 3)) and
            ((not data.exclusiveWith) or (not IsTitleKnown(data.exclusiveWith)))
                then
                
            data.oid = id
            if (not data.unobtainable) then
                table.insert(addon.unknownTitles, data)
            else
                table.insert(addon.unobtainableTitles, data)
            end
        end
    end
end
