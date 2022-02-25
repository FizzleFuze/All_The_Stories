--see Info/LICENSE for licensing and copyright info

local function Log(...)
    FF.Funcs.LogMessage(CurrentModDef.title, "tweaks", ...)
end

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
    if FF.Lib.Debug then
        Log("Update complete, new StoryBit chances:")
        for Category, _ in pairs(Categories) do
            Log(Category, " = ", StoryBitCategories[Category].Chance)
        end
        PrintLog()
    end

    Log("Done UpdateOptions...")
end

--event handling
function OnMsg.ApplyModOptions(id)
    if id == CurrentModId then
        UpdateOptions()
    end
end

OnMsg.ModsReloaded = UpdateOptions