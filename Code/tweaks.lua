--copyright
--[[
*******************************************************************************
Fizzle_Fuze's Surviving Mars Mods
Copyright (c) 2022 Fizzle Fuze Enterprises (mods@fizzlefuze.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

  If your software can interact with users remotely through a computer
network, you should also make sure that it provides a way for users to
get its source.  For example, if your program is a web application, its
interface could display a "Source" link that leads users to an archive
of the code.  There are many ways you could offer source, and different
solutions will be better for different programs; see section 13 for the
specific requirements.

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU AGPL, see
<https://www.gnu.org/licenses/>.
*******************************************************************************
--]]

--mod name
local ModName = "["..CurrentModDef.title.."]"

--variables
local Categories = {
    BuildingConstructed = "Construction",
    ExperimentalRocketLaunched = "ExRocket",
    FounderRocketLanded = "FoundersLanded",
    PlacePrefab = "Prefab",
    RocketLandingAttempt = "Rockets",
    RocketManualLaunch = "Rockets",
    RocketUnloaded = "Rockets",
    SanityBreakdown = "SanityBreakdown",
    TechResearched = "TechResearched",
    Tick = "Tick",
    Tick_BeforeFounders = "Tick",
    Tick_FounderStageDone = "Tick",
    Tick_Terraform = "Terraform",
    ColdWaveEnd = "Disasters",
    ColdWaveStart = "Disasters",
    DustStormEnd = "Disasters",
    DustStromStart = "Disasters",  --SIC
    MeteorStormEnd = "Disasters",
    MeteorStormStart = "Disasters",
    RivalMilestone = "Rivals",
    RivalStartsAnomaly = "Rivals"
}

--logging
local Debugging = false
local Info = false

local function PrintLog()
    local MsgLog = SharedModEnv["Fizzle_FuzeLog"]

    if #MsgLog > 0 then
        --print logged messages to console and file
        for _, Msg in ipairs(MsgLog) do
            print(Msg)
        end
        FlushLogFile()

        --reset
        SharedModEnv["Fizzle_FuzeLog"] = {}
        return
    end
end
if not SharedModEnv["Fizzle_FuzeLog"] then
    SharedModEnv["Fizzle_FuzeLog"] = { ModName.." INFO: First Fizzle_Fuze mod loading!" }
end

local function Fizzle_FuzeLogMessage(...)
    --get the severity, if it is passed in, then format it nicely
    local Sev, Arg = nil, {...}
    local SevType = { "DEBUG", "WARNING", "ERROR", "CRITICAL", "INFO"}

    --first arg = filename, 2nd = severity
    for _, ST in ipairs(SevType) do
        if Arg[2] == ST then
            Sev = ST
            Arg[2] = Arg[2]..": "
            break
        end
    end

    --severity defaults to "DEBUG :"
    if not Sev then
        Sev = "DEBUG: "
        Arg[2] = "DEBUG: "..Arg[2]
    end

    --only log DEBUG and INFO messages during testing
    if Sev == "DEBUG: " and not(Debugging) or (Sev == "INFO: " and not(Info))then
        return
    end

    --log the message
    local MsgLog = SharedModEnv["Fizzle_FuzeLog"]

    --if nothing was passed in, big error
    if #Arg == 0 then
        print(ModName,"/?.lua CRITICAL: No error message!")
        FlushLogFile()
        MsgLog[#MsgLog+1] = ModName.."/?.lua CRITICAL: No error message!"
        SharedModEnv["Fizzle_FuzeLog"] = MsgLog
        return
    end

    --build the message
    local Msg = ModName.."/"..Arg[1]..".lua "
    for i = 2, #Arg do
        Msg = Msg..tostring(Arg[i])
    end

    --set it
    MsgLog[#MsgLog+1] = Msg
    SharedModEnv["Fizzle_FuzeLog"] = MsgLog
end

local function Log(...)
    Fizzle_FuzeLogMessage("tweaks", ...)
end

--update the code based on player options on init and after they're changed
local function UpdateOptions()
    Log("Func UpdateOptions...")

    --add terraforming story-bits to terraforming category if necessary
    if not StoryBitCategory["Tick_Terraform"] then
        Log("INFO", "Creating Terraform category...")
        PlaceObj('StoryBitCategory', {
            Prerequisites = { PlaceObj('FounderStageCompleted', nil), },
            Trigger = "StoryBitTick",
            group = "Terraform",
            id = "Tick_Terraform",})
    end

    for StoryBitCategoryID, _ in pairs(StoryBitCategories) do
        if StoryBitCategoryID == "Tick_Terraform" then
            local TerraformingStoryBits = {
                "BabyVolcano",
                "BrineDeposit",
                "ColdResistantBacteria",
                "CometSighted",
                "Cyanobacteria",
                "DormantLife",
                "IceAsteroid",
                "IronOxidizingBacteria",
                "JunkInSpace",
                "MartianPeace",
                "MartianYellowstone",
                "Pyramid",
                "SeaSponges",
                "ShootingStars",
                "SmokeOnTheWater",
                "StinkyRocks",
                "Tardigrades",
                "TheManFromMars",
                "ThoseDirtyShuttles",
                "WaterNine",
                "WithAGrainOfSalt",
            }

            for _, StoryBit in pairs(StoryBits) do
                for _, TerraformingStoryBit in ipairs(TerraformingStoryBits) do
                    if StoryBit.id == TerraformingStoryBit and StoryBit.Category ~= "Tick_Terraform" then
                        Log("INFO", "Adding ", StoryBit.id, " to Tick_Terraform...")
                        StoryBit.Category = "Tick_Terraform"
                        Log("INFO", "Done: ", StoryBit.Category)
                        goto NextStoryBit
                    end
                end
                ::NextStoryBit::
            end
        end
        break
    end

    --update the chances based on options set
    for Category, Option in pairs(Categories) do
        if not StoryBitCategories[Category].Chance then
            Log("WARNING", "Invalid category: ", Category)
            goto next
        end
        if not Option then
            Log("WARNING", "Invalid option: ", Option)
            goto next
        end
        StoryBitCategories[Category].Chance = CurrentModOptions:GetProperty(Option)
        ::next::
    end

    --debug log
    if Debugging then
        Log("Update complete, new StoryBit chances:")
        for Category, _ in pairs(Categories) do
            Log(Category, " = ", StoryBitCategories[Category].Chance)
        end
        PrintLog()
    end

    Log("Done UpdateOptions...")
end

--event handling
function OnMsg.NewHour()
    if Debugging == true then
        Log("New Hour!")
        PrintLog()
    end
end

--event handling
function OnMsg.NewDay()
    --log errors every day when not debugging
    PrintLog()
end

--event handling
function OnMsg.ApplyModOptions(id)
    --update the code based on player options set for this mod
    if id == CurrentModId then
        UpdateOptions()
    end
end

--event handling
function OnMsg.ModsReloaded(...)
    --update the code based on player options set for this mod
    UpdateOptions()
end