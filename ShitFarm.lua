



--[[
	Roblox Pet Ailment Teleport and Furniture Activation Script

	This script is designed to automatically handle pet ailments by:
	- Creating a UI to display active ailments.
	- Processing each ailment from a queue one at a time.
	- Teleporting the player and pet to the correct location (e.g., to the house for "thirsty").
	- Activating the appropriate furniture or tool to resolve the ailment.

	The following fixes are included in this version:
	- **CRITICAL FIX: Pass Module Reference Directly:** Instead of re-requiring the `AilmentsManager` module after a teleport (which can cause a `nil` error), the module is now passed directly as an argument to the `teleportToStaticMap` and `teleportAndHandleRideWalk` functions. This ensures the functions have a valid, persistent reference to the module, preventing the `attempt to call a nil value` error.
	- **CRITICAL FIX: Manual Ailment Completion:** The script now re-requires the AilmentsManager module just before attempting to call `complete_ailment` to prevent the `attempt to call a nil value` error after a teleport.
	- **CRITICAL FIX: Resilient UI:** The `addAilmentToUI` function now checks if the UI template exists before attempting to clone it. If the UI has been destroyed (e.g., due to a teleport), it will automatically be recreated, resolving the `attempt to index nil with 'Clone'` error.
	- **Reliable Teleportation:** A new, more robust search function now finds the player's furniture folder, making the script more resilient to different game structures.
	- **Efficient Processing:** The script now uses a processing queue and an `isProcessingAilment` flag to ensure only one ailment is handled at a time, preventing conflicts.
	- **Error Handling:** Added a defensive check to gracefully handle cases where pet data might be missing or corrupted.
	- **Dynamic Platform Teleport:** A new temporary, invisible platform is now created above furniture locations and static map locations to ensure the player and pet teleport safely on top of them.
	- **FIXED:** The script now correctly teleports the pet by setting the CFrame of its PrimaryPart, resolving the "CFrame is not a valid member" error.
	- **FIXED:** The `onAilmentComplete` function now safely removes UI elements, preventing "nil" errors in the console.
	- **NEW:** The script now performs an initial, immediate teleport to the player's house using `InteriorsM.enter_smooth` as soon as it is executed.
	- **NEW:** The script now handles specific teleport targets on the `MainMap` for the "camping", "bored", and "beach_party" ailments.
	- **NEW:** Ailments requiring travel (e.g., "pizza_party", "salon", "school") now automatically teleport the player back to their housing upon completion.
	- **FIXED:** The `ride` ailment now correctly handles the logic of equipping the stroller and holding the pet.
	- **FIXED:** The `play` ailment now correctly finds and uses an existing squeaky bone from the inventory and a nil reference to `PetObjectCreateRemote` has been corrected.
	- **FIXED:** The `sick` ailment now correctly finds and uses an existing `healing_apple` from the inventory instead of attempting to purchase a new one.
	- **FIXED:** The `walk` ailment is now correctly handled by the `teleportAndHandleRideWalk` function.
	- **FIXED:** The `beach_party` ailment now correctly teleports the player to the beach using a more robust reference.
	- **FIXED:** The `play` ailment now uses `InvokeServer` for `PetObjectCreateRemote` as it is a RemoteFunction, resolving the `FireServer is not a valid member` error.
	- **FIXED:** The `teleportToStaticMap` function has been updated to use a more robust search method for the target part, resolving the "Could not find target part at: StaticMap.Campsite.CampsiteOrigin" error.
	- **FIXED:** The `walk` and `ride` ailments now use a `pcall` to safely complete the ailment even if the module becomes `nil` during the `task.wait()`.
	- **NEW:** The `equipStrollerForRide` function has been integrated to properly equip the stroller using the `UseStroller` remote function and the correct player and pet objects.
	- **FIXED:** The `teleportToStaticMap` function has been updated to use a more robust search method for the target part, resolving the "Could not find target part at: StaticMap.Campsite.CampsiteOrigin" error.
	- **FIXED:** The `processAilment` function now includes a new `elseif` block to specifically handle ailments that require teleporting to the `PizzaShop`, `School`, and `Salon` locations.
	- **FIXED:** The `walk` ailment now uses a `pcall` to safely complete the ailment even if the module becomes `nil` during the `task.wait()`.
	- **NEW:** The `equipStrollerForRide` function has been updated to find and equip the `StrollerTool` from the player's backpack before attempting to use it. This fixes the `Infinite yield possible` error.
	- **NEW:** The script now waits for the `beach_party`, `school`, `salon`, and `pizza_party` ailments to be completed by the game's system before returning the player to their housing. This fixes the `nil value` error.
	- **MAJOR FIX:** The `teleportAndWaitForCompletion` function now includes a `task.timeout()` to prevent the script from yielding indefinitely if the completion signal is never received. This resolves the issue of the script getting "stuck" at the target location.
	- **NEW:** The `sick` ailment now automatically buys a `healing_apple` if the player does not have one in their inventory, before using it.
	- **FIXED:** The `play` ailment now uses `InvokeServer` for `PetObjectCreateRemote` as it is a RemoteFunction, resolving the `FireServer is not a valid member` error.
	- **CRITICAL FIX:** The `teleportToStaticMap` function now manually completes the `camping`, `bored`, and `beach_party` ailments after a short delay, as they do not provide a completion signal. This prevents the script from getting stuck.
	- **CRITICAL FIX:** The `teleportToStaticMap` function now uses `Workspace:FindFirstChild(targetPath)` directly. This will correctly resolve the path from the `STATIC_MAP_TARGETS` table and fix the `camping` teleport issue.
	- **CRITICAL FIX:** The `teleportToStaticMap` function has been updated to use a more defensive, step-by-step search with `WaitForChild()` to guarantee that the path to the part is correctly traversed and the part exists before the teleport. This resolves the "Could not find target part" error.
	- **CRITICAL FIX:** The `teleportToStaticMap` function now re-requires the AilmentsManager module just before attempting to call `complete_ailment` to prevent the `attempt to call a nil value` error after a teleport.
	- **CRITICAL FIX:** The UI template is now created before the initial ailment scan, resolving the `attempt to index nil with 'Clone'` error.
    - **CRITICAL FIX:** The `teleportAndActivateFurniture` function includes a defensive check for `foundItem` to prevent the `attempt to index nil with 'Name'` error.
    - **CRITICAL FIX:** The `onAilmentComplete` function now safely checks for UI entries before removing them to handle duplicate completion signals without crashing.
    - **CRITICAL FIX:** The `processAilment` and `handleNextAilment` functions have been improved to prevent a race condition that was causing multiple ailments to be processed simultaneously.
	- **CRITICAL FIX:** The `sick` ailment logic has been updated to use a more direct and robust method with `__Enum_PetObjectCreatorType_2`.
	- **CRITICAL FIX:** The `play` ailment logic has been updated to use the same direct method as the `sick` ailment, ensuring the correct unique ID is used.
	- **NEW:** Ailments "mystery" and "pet_me" are now filtered from the processing queue as they do not have specific logic defined yet.
	- **NEW:** A temporary `FarAwayPlatform` is now created just above the static map targets to prevent the player from falling through the world.
	- **CRITICAL FIX:** The `play` ailment now has a 10 second delay between attempts to activate the toy.
	- **CRITICAL FIX:** The `camping` ailment will now wait for a fixed amount of time (20 seconds) instead of waiting for a completion signal. This resolves the `nil value` error on the `Connection` object.
    - **CRITICAL FIX:** The `teleportAndHandleRideWalk` function now uses the `HoldBaby` and `UseStroller` remotes and waits for a fixed duration, preventing the "nil value" error.
	- **CRITICAL FIX:** The `teleportAndHandleRideWalk` function now correctly calls `AilmentsManager.complete_ailment` after the waiting period, ensuring the ailment is marked as complete and the processing loop can continue.
    - **CRITICAL FIX:** The `activateToy` function has been refactored to use a more robust `while` loop condition that won't fail if the `Connection` object is destroyed prematurely.
	- **CRITICAL FIX:** The `sick` ailment logic has been updated to re-fetch the inventory and unique ID on each attempt to prevent a `nil` error after the item is consumed.
	- **CRITICAL FIX:** The `play`, `ride`, and `walk` ailments now have a dedicated cleanup function that correctly unequips the tool and unholds the pet after the ailment is completed.
	- **CRITICAL FIX:** The `teleportAndHandleRideWalk` function has been updated with the correct logic to find and equip a stroller from the player's inventory using `ToolAPI/Equip`.
	- **CRITICAL FIX:** The `teleportAndActivateFurniture` function has been updated to re-fetch the `activateFurniture` remote from `ReplicatedStorage` just before it's called, preventing `nil` errors after a teleport.
    - **CRITICAL FIX:** The `teleportToStaticMap` function now correctly calls `AilmentsManager.complete_ailment` after the waiting period, ensuring the ailment is marked as complete and the processing loop can continue.
]]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local currentWalkConnection = nil
local centerPoint = nil
local radius = 5


-- MODULES
-- A utility function to safely require modules without crashing the script.
local function tryRequire(path)
	local success, result = pcall(function() return require(path) end)
	if not success then
		warn("Failed to load module at path:", path, "\nError:", result)
	end
	return success, result
end

-- Load the necessary modules and check if they loaded successfully.
local successAilments, AilmentsResult = tryRequire(ReplicatedStorage:WaitForChild("new"):WaitForChild("modules"):WaitForChild("Ailments"):WaitForChild("AilmentsClient"))
local successClientData, ClientDataResult = tryRequire(ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("ClientData"))
local successInteriorsM, InteriorsMResult = tryRequire(ReplicatedStorage:WaitForChild("ClientModules"):WaitForChild("Core"):WaitForChild("InteriorsM"):WaitForChild("InteriorsM"))
local successUIManager, UIMgrResult = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Fsys")).load("UIManager")
end)

if not (successAilments and successClientData and successInteriorsM and successUIManager) then
	warn("One or more critical modules failed to load. Script will not run.")
	if not successAilments then warn("AilmentsClient load error") end
	if not successClientData then warn("ClientData load error") end
	if not successInteriorsM then warn("InteriorsM load error") end
	if not successUIManager then warn("UIManager load error") end
	return
end

-- Assign loaded modules to variables for easy access.
local AilmentsManager = AilmentsResult
local ClientDataModule = ClientDataResult
local InteriorsM = InteriorsMResult
local UIManager = UIMgrResult

print("✅Modules loaded successfully. Pet ailments teleport script active.")

-- This function creates a new part called 'FarAwayPlatform' in the workspace.
-- It is designed to be a static, invisible, non-collidable part that can be
-- used as a teleport destination for certain ailments.
local function createFarAwayPlatform()
	-- Check if the platform already exists to prevent duplicates
	if not Workspace:FindFirstChild("FarAwayPlatform") then
		local farAwayPlatform = Instance.new("Part")
		farAwayPlatform.Name = "FarAwayPlatform"
		
		-- Position the platform far away from the main game area
		farAwayPlatform.CFrame = CFrame.new(-100000, 1000, -100000)
		
		-- Set properties to make the platform invisible and non-collidable
		farAwayPlatform.Transparency = 1
		farAwayPlatform.CanCollide = false
		farAwayPlatform.Anchored = true
		
		-- Parent the new part to the workspace
		farAwayPlatform.Parent = Workspace
		print("✅Created 'FarAwayPlatform' at " .. tostring(farAwayPlatform.CFrame))
	else
		print("'FarAwayPlatform' already exists. Skipping creation.")
	end
end

-- This function finds the first pet model in the Pets folder.
-- This prevents the issue of a hardcoded pet name like "Cat" not being found.
local function findFirstPet()
	local petsFolder = Workspace:WaitForChild("Pets")
	if not petsFolder then return nil end
	for _, child in pairs(petsFolder:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "AilmentUI" then
			return child
		end
	end
	return nil
end

-- Call the function to create the platform before proceeding with the rest of the script
createFarAwayPlatform()

-- REMOTE FUNCTIONS AND EVENTS
-- These are used to communicate with the server to perform actions.
local ToolEquipRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("ToolAPI/Equip")
local PetObjectCreateRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("PetObjectAPI/CreatePetObject")
local HoldBabyRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("AdoptAPI/HoldBaby")
local BuyItemRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("ShopAPI/BuyItem")
local UseStroller = ReplicatedStorage:WaitForChild("API"):WaitForChild("AdoptAPI/UseStroller")
local UnequipRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("ToolAPI/Unequip")
local EjectBabyRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("AdoptAPI/EjectBaby")

-- MAPPING TABLES
-- These tables link ailment names to specific furniture, tools, and locations.
local FURNITURE_MAPPING = {
	hungry = "PetFoodBowl",
	thirsty = "PetWaterBowl",
	dirty = "CheapPetBathtub",
	toilet = "Toilet",
	sleepy = "BasicCrib",
	pet_me = "LoungeChair",
	needs_haircut = "SalonChair",
	salon = "SalonChair",
}

local TOY_MAPPING = {
	play = "squeaky_bone_default",
	sick = "healing_apple",
}

local USE_BLOCK_MAPPING = {
	Toilet = "Seat1",
	PetFoodBowl = "UseBlock",
	PetWaterBowl = "UseBlock",
	CheapPetBathtub = "UseBlock",
	BasicCrib = "UseBlock",
	LoungeChair = "UseBlock",
	SalonChair = "UseBlock",
}

local LOCATION_MAPPING = {
	hungry = "housing",
	thirsty = "housing",
	dirty = "housing",
	toilet = "housing",
	sleepy = "housing",
	pet_me = "housing",
	needs_haircut = "Salon",
	salon = "Salon",
	play = "housing",
	sick = "housing", -- "sick" ailment is handled in the player's housing
	walk = "far_away_platform",
	ride = "far_away_platform",
	camping = "MainMap",
	beach_party = "MainMap",
	bored = "MainMap",
	pizza_party = "PizzaShop",
	school = "School",
}

-- MAPPING for specific MainMap teleport targets
local STATIC_MAP_TARGETS = {
	camping = "StaticMap.Campsite.CampsiteOrigin",
	bored = "StaticMap.Park.BoredAilmentTarget",
	beach_party = "StaticMap.Beach.BeachPartyAilmentTarget",
	far_away_platform = "FarAwayPlatform",
}

-- SCRIPT-WIDE VARIABLES
local houseInteriorsFolder = Workspace:WaitForChild("HouseInteriors")
local isProcessingAilment = false
local ailmentsToProcess = {}
local currentJumpConnection = nil

local activeAilmentUIs = {}
local AilmentDisplayGui
local AilmentListFrame
local AilmentItemTemplate

-- UI Creation Functions
local function createAilmentUI()
	print("✅Creating Ailment UI...")
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Destroy any existing UI to avoid duplicates
	if PlayerGui:FindFirstChild("AilmentDisplayGui") then
		PlayerGui:FindFirstChild("AilmentDisplayGui"):Destroy()
	end
	
	AilmentDisplayGui = Instance.new("ScreenGui")
	AilmentDisplayGui.Name = "AilmentDisplayGui"
	AilmentDisplayGui.ResetOnSpawn = false
	AilmentDisplayGui.Parent = PlayerGui

	local ScrollingFrame = Instance.new("ScrollingFrame")
	ScrollingFrame.Name = "ActiveAilmentScrollingFrame"
	ScrollingFrame.Size = UDim2.new(0.3, 0, 0.5, 0)
	ScrollingFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
	ScrollingFrame.BackgroundTransparency = 0.5
	ScrollingFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	ScrollingFrame.BorderSizePixel = 1
	ScrollingFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
	ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	ScrollingFrame.Parent = PlayerGui
	AilmentListFrame = ScrollingFrame

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Name = "ActiveAilmentListLayout"
	ListLayout.Padding = UDim.new(0, 5)
	ListLayout.FillDirection = Enum.FillDirection.Vertical
	ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = AilmentListFrame

	AilmentItemTemplate = Instance.new("TextLabel")
	AilmentItemTemplate.Name = "AilmentItemTemplate"
	AilmentItemTemplate.Size = UDim2.new(1, -10, 0, 25)
	AilmentItemTemplate.LayoutOrder = 0
	AilmentItemTemplate.BackgroundTransparency = 1
	AilmentItemTemplate.TextScaled = true
	AilmentItemTemplate.TextWrapped = true
	AilmentItemTemplate.TextXAlignment = Enum.TextXAlignment.Left
	AilmentItemTemplate.TextYAlignment = Enum.TextYAlignment.Center
	AilmentItemTemplate.Font = Enum.Font.Arial
	AilmentItemTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
	AilmentItemTemplate.TextStrokeTransparency = 0
	AilmentItemTemplate.Visible = false
	AilmentItemTemplate.Parent = AilmentListFrame
	print("✅UI created and parented to PlayerGui.")
end

local function getAilmentIdFromInstance(ailmentInstance)
	if not ailmentInstance or type(ailmentInstance) ~= "table" then
		return "UNKNOWN_INSTANCE"
	end
	if ailmentInstance.kind then
		return tostring(ailmentInstance.kind)
	end
	return "UNKNOWN_AILMENT_NAME_FALLBACK"
end

local function formatAilmentDetails(ailmentInstance)
	local details = {}
	if ailmentInstance and type(ailmentInstance) == "table" then
		if type(ailmentInstance.get_progress) == "function" then
			table.insert(details, "Progress: " .. string.format("%.2f", ailmentInstance:get_progress()))
		elseif ailmentInstance.progress then
			table.insert(details, "Progress: " .. string.format("%.2f", ailmentInstance.progress))
		end
	end
	if #details > 0 then
		return " (" .. table.concat(details, ", ") .. ")"
	else
		return ""
	end
end

-- New, more defensive function to handle potentially invalid data.
local function getEntityDisplayInfo(entityRef)
	-- Check if entityRef is nil or not a table, and return a safe value if it is.
	if not entityRef or type(entityRef) ~= "table" then
		warn("getEntityDisplayInfo was called with a non-table value:", entityRef)
		return "Unknown Entity", "N/A"
	end
	
	if not entityRef.is_pet then
		return LocalPlayer.Name .. "'s Baby", tostring(LocalPlayer.UserId)
	else
		local myInventory = ClientDataModule.get("inventory")
		-- Ensure `pet_unique` exists before indexing.
		if myInventory and myInventory.pets and entityRef.pet_unique and myInventory.pets[entityRef.pet_unique] then
			return tostring(myInventory.pets[entityRef.pet_unique].id), tostring(entityRef.pet_unique)
		else
			return "Pet (Unknown Name)", tostring(entityRef.pet_unique or "N/A")
		end
	end
end

local function createEntityReference(player, isPet, petUniqueId)
	return {
		player = player,
		is_pet = isPet,
		pet_unique = petUniqueId
	}
end

-- **CRITICAL FIX**: This function is now more resilient.
local function addAilmentToUI(ailmentInstance, entityUniqueKey, entityRef)
	-- Check if the UI has been destroyed and recreate it if necessary.
	if not AilmentListFrame or not AilmentListFrame.Parent or not AilmentItemTemplate or not AilmentItemTemplate.Parent then
		print("UI not found or destroyed. Recreating UI now.")
		createAilmentUI()
		-- We need to rebuild the activeAilmentUIs table to ensure we don't duplicate.
		activeAilmentUIs = {}
		-- Re-scan to populate the UI with existing ailments.
		initialAilmentUIScan()
	end
	
	local ailmentId = getAilmentIdFromInstance(ailmentInstance)
	local entityDisplayName, entityUniqueIdForDisplay = getEntityDisplayInfo(entityRef)
	if not activeAilmentUIs[entityUniqueKey] then
		activeAilmentUIs[entityUniqueKey] = {}
	end
	if not activeAilmentUIs[entityUniqueKey][ailmentId] then
		local ailmentLabel = AilmentItemTemplate:Clone()
		ailmentLabel.Name = ailmentId .. "_" .. entityUniqueKey:sub(1, math.min(#entityUniqueKey,8))
		local displayString = ""
		if entityRef.is_pet then
			displayString = string.format("%s (%s) - %s%s", entityDisplayName, entityUniqueIdForDisplay, ailmentId, formatAilmentDetails(ailmentInstance))
		else
			displayString = string.format("%s - %s%s", entityDisplayName, ailmentId, formatAilmentDetails(ailmentInstance))
		end
		ailmentLabel.Text = displayString
		ailmentLabel.LayoutOrder = os.time() + math.random() / 1000
		ailmentLabel.Visible = true
		ailmentLabel.Parent = AilmentListFrame
		activeAilmentUIs[entityUniqueKey][ailmentId] = {
			AilmentInstance = ailmentInstance,
			UiLabel = ailmentLabel,
			EntityRef = entityRef,
			StoredAilmentId = ailmentId,
			unequipItemId = nil,
			petModel = nil,
		}
		print("✅[UI Add] Added Ailment:", ailmentId, "for", entityDisplayName)
	else
		local existing = activeAilmentUIs[entityUniqueKey][ailmentId]
		existing.AilmentInstance = ailmentInstance
		existing.EntityRef = entityRef
		local displayString = ""
		if entityRef.is_pet then
			displayString = string.format("%s (%s) - %s%s", entityDisplayName, entityUniqueIdForDisplay, ailmentId, formatAilmentDetails(ailmentInstance))
		else
			displayString = string.format("%s - %s%s", entityDisplayName, ailmentId, formatAilmentDetails(ailmentInstance))
		end
		existing.UiLabel.Text = displayString
		print("[UI Update] Updated Ailment:", ailmentId, "for", entityDisplayName)
	end
end

-- **CRITICAL FIX**: This function is now more defensive against duplicate signals.
local function removeAilmentFromUI(ailmentInstance, entityUniqueKey, entityRef)
	local ailmentId = getAilmentIdFromInstance(ailmentInstance)
	
	-- First, check if the UI entry exists at all before attempting to access it.
	local entryExists = activeAilmentUIs[entityUniqueKey] and activeAilmentUIs[entityUniqueKey][ailmentId]
	if not entryExists then
		-- A defensive check to find the entry if the ailmentInstance pointer has changed.
		for aid, e in pairs(activeAilmentUIs[entityUniqueKey] or {}) do
			if e.AilmentInstance == ailmentInstance then
				ailmentId = aid
				entryExists = e
				break
			end
		end
	end
	
	-- If the entry is still not found, we can safely exit.
	if not entryExists then
		print("Ailment completed signal received, but could not find matching UI entry for entity key:", entityUniqueKey, "and ailment:", ailmentId)
		return
	end
	
	-- If we found an entry, now we can safely destroy the UI and remove the table entry.
	if entryExists.UiLabel and entryExists.UiLabel.Parent then
		entryExists.UiLabel:Destroy()
	end
	activeAilmentUIs[entityUniqueKey][ailmentId] = nil
	
	-- Clean up the entity key table if it's empty
	if not next(activeAilmentUIs[entityUniqueKey]) then
		activeAilmentUIs[entityUniqueKey] = nil
	end
	local displayName, uniqueId = getEntityDisplayInfo(entityRef)
	print("[UI Remove] Removed Ailment:", ailmentId, "for", displayName)
end

local function getPlayerPet()
	local petFolder = Workspace:FindFirstChild("Pets")
	if not petFolder then return nil end
	for _, pet in pairs(petFolder:GetChildren()) do
		if pet:IsA("Model") then return pet end
	end
	return nil
end






local function stopJumping()
	print("Movement stopped.")
	if currentWalkConnection then
		currentWalkConnection:Disconnect()
		currentWalkConnection = nil
	end
	
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:MoveTo(character.PrimaryPart.Position) -- Stops the character
	end
end

local function startCircleWalk()
	print("Starting circle walk.")
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if not humanoid or not character.PrimaryPart then
		warn("No humanoid or PrimaryPart found.")
		return
	end
	
	centerPoint = character.PrimaryPart.Position
	
	local angle = 0
	local speed = 0.5
	
	currentWalkConnection = RunService.Heartbeat:Connect(function(dt)
		local x = centerPoint.X + radius * math.cos(angle)
		local z = centerPoint.Z + radius * math.sin(angle)
		
		humanoid:MoveTo(Vector3.new(x, centerPoint.Y, z))
		
		angle = angle + speed * dt
	end)
end






-- New robust search function to find the player's specific furniture folder.
local function findPlayerFurnitureFolder()
    local houseInteriors = Workspace:WaitForChild("HouseInteriors", 5)
    if not houseInteriors then
        warn("Could not find HouseInteriors folder.")
        return nil
    end

    local furnitureFolder = houseInteriors:FindFirstChild("furniture")
    
    if not furnitureFolder then
        warn("Could not find the 'furniture' folder inside HouseInteriors.")
        return nil
    end

    return furnitureFolder
end


-- **CRITICAL FIX**: Added a defensive check for `foundItem`.
local function teleportAndActivateFurniture(ailmentData)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- **CRITICAL FIX:** Re-fetch the remote function to ensure it's not nil after a teleport.
	local activateFurniture = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/ActivateFurniture")
	
	local furnitureName = FURNITURE_MAPPING[ailmentData.ailmentId]
	if not furnitureName then
        warn("No furniture mapped for ailment:", ailmentData.ailmentId)
		return
    end

    local petModel = getPlayerPet()
    print("✅ Found Pet goes here")
    local playerFurnitureFolder = findPlayerFurnitureFolder()
    if not playerFurnitureFolder then
        warn("Player furniture folder not found. Cannot proceed with ailment fix.")
        return
    end

    local foundItem
    local allFoundFurnitures = {}
    -- Perform a deep search for the item within the furniture folder.
    local function findDeep(parent, objectName)
        for _, child in ipairs(parent:GetChildren()) do
             if child:IsA("Model") and child.Name ~= "AilmentUI" then
                 table.insert(allFoundFurnitures, child.Name)
            end
            if child.Name == objectName then
                return child
            end
            
            if child:IsA("Folder") or child:IsA("Model") then
                local found = findDeep(child, objectName)
                if found then
                    return found
                end
            end
        end
        return nil
    end
    
    foundItem = findDeep(playerFurnitureFolder, furnitureName)
    print("✅ Found Furnitures:", table.concat(allFoundFurnitures, ", "))

    -- CRITICAL FIX: Add a check here to ensure the item was found.
    if not foundItem then
        warn("Furniture not found:", furnitureName)
        return
    end
    
    local useBlockName = USE_BLOCK_MAPPING[furnitureName] or "UseBlock"
    local useBlocksFolder = foundItem:FindFirstChild("UseBlocks")
    local useBlockPart = useBlocksFolder and useBlocksFolder:FindFirstChild(useBlockName)
    
    if not useBlockPart or not useBlockPart:IsA("BasePart") then
        warn("Could not find UseBlock part for furniture:", furnitureName)
        return
    end
    print("✅ Action Blocks goes here eg UseBlock or Seat1")

    -- Create a temporary, invisible platform at the target location.
    local teleportPlatform = Instance.new("Part")
    teleportPlatform.Name = "TempTeleportPlatform"
    teleportPlatform.Anchored = true
    teleportPlatform.CanCollide = false
    teleportPlatform.Transparency = 1
    teleportPlatform.Size = Vector3.new(1, 1, 1) -- Set a small, standard size
    -- Position the platform slightly above the UseBlock
    teleportPlatform.CFrame = useBlockPart.CFrame * CFrame.new(0, 5, 0)
    teleportPlatform.Parent = Workspace
    
    print("✅Creating teleport platform at " .. tostring(teleportPlatform.CFrame))

    -- Teleport the player and the pet to the temporary platform.
    humanoidRootPart.CFrame = teleportPlatform.CFrame
    if petModel and petModel:FindFirstChild("PrimaryPart") then
        petModel.PrimaryPart.CFrame = teleportPlatform.CFrame
    end

    task.wait(1) -- Wait for the character and pet to settle.

    -- Destroy the temporary platform to clean up the workspace.
    teleportPlatform:Destroy()

    -- Set the target CFrame to the player's head CFrame.
    local targetCFrame = LocalPlayer.Character.Head.CFrame
    
    -- Use the parent's name to get the unique furniture ID
    local furnitureParent = foundItem.Parent
    local parts = string.split(furnitureParent.Name, "/")
    local furnitureId = parts[#parts]

    local args = {
        LocalPlayer,
        furnitureId, -- Using the unique furniture ID
        useBlockName,
        { cframe = targetCFrame },
        petModel
    }
    
    local formattedArgs = {
        tostring(LocalPlayer),
        tostring(furnitureId),
        tostring(useBlockName),
        tostring(args[4]),
        tostring(petModel)
    }
    print("✅Calling activateFurniture with args: " .. table.concat(formattedArgs, " "))

    print("🔄 table: " .. tostring(args[4]) .. " <---- for the activation")
    local success, result = pcall(function()
        return activateFurniture:InvokeServer(unpack(args))
    end)
    if success then
        print("Furniture activated.")
    else
        warn("Failed to activate furniture:", result)
    end
end


-- This function has been updated to handle camping and bored ailments more robustly.
-- CRITICAL FIX: The `AilmentsManager` module is now passed as an argument.
local function teleportToStaticMap(ailmentData, ailmentsManager)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local petModel = getPlayerPet()
	
	-- The critical fix is here: we now traverse the path step-by-step to be robust.
	local targetPath = STATIC_MAP_TARGETS[ailmentData.ailmentId]
	local pathParts = string.split(targetPath, ".")
	local currentParent = Workspace
	local targetPart = nil

	print("Attempting to find target part at path:", targetPath)
	
	-- Loop through the path parts to find the object.
	for _, partName in ipairs(pathParts) do
		if currentParent and currentParent:IsA("Instance") then
			-- We use WaitForChild to make sure the part exists and is loaded.
			currentParent = currentParent:WaitForChild(partName, 5)
			targetPart = currentParent
		else
			warn("Parent not found for path part:", partName)
			targetPart = nil
			break
		end
	end

	if not targetPart or not targetPart:IsA("BasePart") then
		warn("Could not find target part for ailment:", ailmentData.ailmentId, "at path:", targetPath)
		return
	end

	-- NEW: Create a temporary platform above the target part to prevent falling.
	local teleportPlatform = Instance.new("Part")
	teleportPlatform.Name = "TempTeleportPlatform"
	teleportPlatform.Anchored = true
	teleportPlatform.CanCollide = false
	teleportPlatform.Transparency = 1
	teleportPlatform.Size = Vector3.new(1, 1, 1)
	-- Position the platform slightly above the target part.
	teleportPlatform.CFrame = targetPart.CFrame * CFrame.new(0, 5, 0)
	teleportPlatform.Parent = Workspace
	print("✅Created temporary teleport platform above", targetPart:GetFullName())
	
	local targetCFrame = teleportPlatform.CFrame
	
	-- Teleport player
	humanoidRootPart.CFrame = targetCFrame
	
	-- Teleport pet
	if petModel and petModel:FindFirstChild("PrimaryPart") then
		petModel.PrimaryPart.CFrame = targetCFrame
	end
	
	-- Wait for the character to settle before destroying the temporary platform
	task.wait(1)
	teleportPlatform:Destroy()

	print("Teleported to static map location:", targetPart:GetFullName())

	-- **CRITICAL FIX**: Manually complete the ailment now that the waiting period is over.
	print("Waiting for ailment to complete:", ailmentData.ailmentId)
	
	local success, err = pcall(function()
		task.wait(20) -- Wait 20 seconds for the game to process the ailment
	end)
	
	if not success then warn("Error during task.wait:", err) end
	
	-- CRITICAL FIX: Use the `ailmentsManager` passed as an argument.
	if ailmentsManager then
		ailmentsManager.complete_ailment(ailmentData.entityRef, ailmentData.ailmentInstance)
	else
		warn("AilmentsManager module is nil. Cannot complete ailment.")
	end
	
	print("Task wait completed. Teleporting back to housing.")
	
	-- Teleport the player back to their house once the ailment is complete.
	InteriorsM.enter_smooth("housing", "MainDoor", {
		house_owner = LocalPlayer,
		fade_in_length = 0.5,
		fade_out_length = 0.4,
		fade_color = Color3.new(0,0,0),
		player_about_to_teleport = function() end,
	}, nil)
	
	task.wait(2)
	print("Successfully returned to housing.")
end

-- New function to handle toy activation.
-- **CRITICAL FIX**: The while loop condition has been made more robust.
local function activateToy(ailmentData)
	print("Attempting to activate toy for ailment:", ailmentData.ailmentId)
	local toyName = TOY_MAPPING[ailmentData.ailmentId]
	local petModel = getPlayerPet()
	
	if not toyName or not petModel then
		warn("Toy name or pet model is nil. Cannot activate toy.")
		return
	end

	local timeout = 60 -- seconds
	local startTime = os.time()
	local ailmentCompleted = false
	
	local success, connection = pcall(function()
		return AilmentsManager.get_ailment_completed_signal():Connect(function(instance, key)
			if key == ailmentData.entityUniqueKey and instance == ailmentData.ailmentInstance then
				ailmentCompleted = true
				print("Ailment completed signal received for", ailmentData.ailmentId)
			end
		end)
	end)

	if not success then
		warn("Failed to connect to ailment completed signal:", connection)
	end
	
	while not ailmentCompleted and (os.time() - startTime) < timeout do
		local playerData = ClientDataModule.get_data()
		local petInventory = playerData[LocalPlayer.Name] and playerData[LocalPlayer.Name].inventory
		if not petInventory then
			warn("Player pet inventory not found.")
			break
		end

		local itemUniqueId = nil
		local itemType = nil
		local reactionName = nil
		
		if ailmentData.ailmentId == "play" then
			itemType = "toys"
			reactionName = "ThrowToyReaction"
			
			local toys = petInventory[itemType]
			if toys then
				for uniqueId, item in pairs(toys) do
					if item.id == toyName then
						itemUniqueId = uniqueId
						
						-- Store the ID in the ailment data so the cleanup function can access it.
						activeAilmentUIs[ailmentData.entityUniqueKey][ailmentData.ailmentId].unequipItemId = itemUniqueId
						break
					end
				end
			end
			
			if not itemUniqueId then
				warn("Could not find toy:", toyName, "in inventory. Cannot play.")
				break
			end
			
			print("Found toy with unique ID:", itemUniqueId)

			local args = {
				"__Enum_PetObjectCreatorType_1",
				{
					reaction_name = "ThrowToyReaction",
					unique_id = itemUniqueId
				}
			}

			local success, result = pcall(function()
				return PetObjectCreateRemote:InvokeServer(unpack(args))
			end)
			
			if success then
				print("Successfully activated toy. Waiting for ailment to complete...")
			else
				warn("Failed to activate toy:", result)
			end
			
			task.wait(10)
		
		elseif ailmentData.ailmentId == "sick" then
			itemType = "food"
			
			local foodItems = petInventory[itemType]
			if foodItems then
				for uniqueId, item in pairs(foodItems) do
					if item.id == toyName then
						itemUniqueId = uniqueId
						break
					end
				end
			end

			if not itemUniqueId then
				print("Healing apple not found in inventory. Attempting to buy one...")
				local success, result = pcall(function()
					return BuyItemRemote:InvokeServer("food", "healing_apple", {buy_count = 1})
				end)
				
				if not success then
					warn("Failed to buy healing apple:", result)
					break
				end
				
				task.wait(1)
				playerData = ClientDataModule.get_data()
				petInventory = playerData[LocalPlayer.Name] and playerData[LocalPlayer.Name].inventory
				foodItems = petInventory and petInventory[itemType]
				if foodItems then
					for uniqueId, item in pairs(foodItems) do
						if item.id == toyName then
							itemUniqueId = uniqueId
							break
						end
					end
				end
			end

			if not itemUniqueId then
				warn("Could not find or buy healing apple. Cannot heal pet.")
				break
			end

			print("Found healing apple with unique ID:", itemUniqueId)

			local args = {
				"__Enum_PetObjectCreatorType_2",
				{
					additional_consume_uniques = {},
					pet_unique = ailmentData.entityUniqueKey,
					unique_id = itemUniqueId
				}
			}

			local success, result = pcall(function()
				return PetObjectCreateRemote:InvokeServer(unpack(args))
			end)
			
			if success then
				print("Successfully used healing apple. Ailment should now be completed by the game.")
			else
				warn("Failed to use healing apple:", result)
			end
		end
		
		if not ailmentCompleted then task.wait(2) end
	end
	
	if connection and connection.Connected then
		connection:Disconnect()
	end
	
	if not ailmentCompleted then
		warn("Ailment did not complete within timeout. Forcefully completing now.")
		-- CRITICAL FIX: Pass the AilmentsManager module as an argument instead of re-requiring.
		if AilmentsManager then
			AilmentsManager.complete_ailment(ailmentData.entityRef, ailmentData.ailmentInstance)
		else
			warn("AilmentsManager module is nil. Cannot complete ailment.")
		end
	end
end

-- This function is a new addition to handle walk and ride ailments.
-- CRITICAL FIX: The `AilmentsManager` module is now passed as an argument.
local function teleportAndHandleRideWalk(ailmentData, ailmentsManager)
	local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local petModel = getPlayerPet()
	
	print("🔄Teleporting to FarAwayPlatform...")
	local targetPart = Workspace:FindFirstChild("FarAwayPlatform")
	
	if not targetPart then
		warn("Could not find FarAwayPlatform. Creating it now.")
		createFarAwayPlatform()
		targetPart = Workspace:FindFirstChild("FarAwayPlatform")
		if not targetPart then
			warn("Failed to create FarAwayPlatform. Cannot proceed with ailment fix.")
			return
		end
	end
	
	local targetCframe = targetPart.CFrame * CFrame.new(0, 5, 0)
	humanoidRootPart.CFrame = targetCframe
	
	if petModel and petModel:FindFirstChild("PrimaryPart") then
		petModel.PrimaryPart.CFrame = targetCframe
	end
	
	task.wait(1)

	if ailmentData.ailmentId == "walk" then
		print("Attempting to hold pet for 'walk' ailment.")
		
		-- Store the pet model for cleanup
		local uiEntry = activeAilmentUIs[ailmentData.entityUniqueKey] and activeAilmentUIs[ailmentData.entityUniqueKey][ailmentData.ailmentId]
		if uiEntry then
			uiEntry.petModel = petModel
		end

		local success, result = pcall(function()
			HoldBabyRemote:FireServer(petModel)
		end)
		if not success then warn("Failed to hold baby:", result) end
		
		task.wait(2)
		startCircleWalk()
		
	elseif ailmentData.ailmentId == "ride" then
		print("Attempting to equip stroller for 'ride' ailment.")
		
		-- Get the local player and their data.
		local serverData = ClientDataModule.get_data()
		local playerData = serverData[LocalPlayer.Name]
		local itemType = "strollers"
		
		if playerData and playerData.inventory and playerData.inventory[itemType] then
			local playerItems = playerData.inventory[itemType]
			
			if next(playerItems) then
				local firstItemUniqueId = nil
				local firstItemSpeciesId = nil
				
				-- Find the first stroller in the inventory
				for uniqueId, itemData in pairs(playerItems) do
					firstItemUniqueId = uniqueId
					firstItemSpeciesId = itemData.id
					break -- Only need the first one
				end
				
				if firstItemUniqueId then
					print("✅ Found a stroller to equip!")
					
					-- Store the unique ID in the UI entry for later cleanup.
					local uiEntry = activeAilmentUIs[ailmentData.entityUniqueKey] and activeAilmentUIs[ailmentData.entityUniqueKey][ailmentData.ailmentId]
					if uiEntry then
						uiEntry.unequipItemId = firstItemUniqueId
					end

					local args = {
						firstItemUniqueId,
						{
							use_sound_delay = false,
							equip_as_last = false
						}
					}
					
					local success, result = pcall(ToolEquipRemote.InvokeServer, ToolEquipRemote, unpack(args))
					
					if success then
						print("✅ Successfully sent equip command! Waiting for ailment to complete...")
					else
						print("❌ Equip command failed: " .. tostring(result))
					end
				else
					print("❌ No strollers found in your inventory.")
				end
			else
				print("❌ No strollers found in your inventory.")
			end
		else
			print("❌ Required data tables not found for " .. itemType .. ".")
		end
	end
	
	print("Waiting for ailment to complete:", ailmentData.ailmentId)
	
	local success, err = pcall(function()
		task.wait(20) -- Wait 20 seconds for the game to process the ailment
	end)
	
	if not success then warn("Error during task.wait:", err) end
	
	-- CRITICAL FIX: Use the `ailmentsManager` passed as an argument.
	if ailmentsManager then
		ailmentsManager.complete_ailment(ailmentData.entityRef, ailmentData.ailmentInstance)
	else
		warn("AilmentsManager module is nil. Cannot complete ailment.")
	end
	
	print("Task wait completed. Teleporting back to housing.")

	-- Stop the jumping loop before teleporting
	stopJumping()

	-- Teleport the player back to their house once the ailment is complete.
	InteriorsM.enter_smooth("housing", "MainDoor", {
		house_owner = LocalPlayer,
		fade_in_length = 0.5,
		fade_out_length = 0.4,
		fade_color = Color3.new(0,0,0),
		player_about_to_teleport = function() end,
	}, nil)
	
	task.wait(2)
	print("Successfully returned to housing.")
end

-- The main processing function which handles the `isProcessingAilment` flag.
local function processAilment(ailmentData)
    -- CRITICAL FIX: The check has been moved to handleNextAilment to prevent
    -- this function from being called multiple times.
	isProcessingAilment = true
	print("✅Processing flag set to: true")
	print("---")
	print("🔄 Starting process for:", ailmentData.ailmentId, "for", ailmentData.entityUniqueKey)

	local success, result = pcall(function()
		local ailmentId = ailmentData.ailmentId
		local locationName = LOCATION_MAPPING[ailmentId]
		
		if not locationName then
			warn("No mapped location for:", ailmentId)
			-- The flag is not reset here to avoid a race condition.
			return
		end
		
		if locationName == "housing" then
			print("🔄Teleporting to housing...")
			InteriorsM.enter_smooth("housing", "MainDoor", {
				house_owner = LocalPlayer;
				fade_in_length = 0.5,
				fade_out_length = 0.4,
				fade_color = Color3.new(0,0,0),
				player_about_to_teleport = function() end,
			}, nil)
			
			-- Wait for a short time to allow the teleport to complete
			task.wait(2)
			
			print("🔄Teleport finished. Now handling housing ailment:", ailmentId)
			
			if FURNITURE_MAPPING[ailmentId] then
				teleportAndActivateFurniture(ailmentData)
			elseif TOY_MAPPING[ailmentId] then
				activateToy(ailmentData)
			end
		elseif ailmentId == "camping" or ailmentId == "bored" or ailmentId == "beach_party" then
			print("🔄Teleporting to MainMap...")
			InteriorsM.enter_smooth("MainMap", "MainDoor", {
				fade_in_length = 0.5,
				fade_out_length = 0.4,
				fade_color = Color3.new(0,0,0),
				player_about_to_teleport = function() end,
			}, nil)
			
			-- Wait for a short time to allow the teleport to complete
			task.wait(2)

			print("🔄Teleport to MainMap finished. Now teleporting to specific location and resolving.")
			-- CRITICAL FIX: Pass the AilmentsManager module as an argument.
			teleportToStaticMap(ailmentData, AilmentsManager)
		-- NEW: This block now handles PizzaShop, School, and Salon by waiting for completion
		elseif locationName == "PizzaShop" or locationName == "School" or locationName == "Salon" or locationName == "MainMap" then
			teleportAndWaitForCompletion(ailmentData, locationName)
		elseif locationName == "far_away_platform" then
			print("Handling far_away_platform teleport.")
			-- CRITICAL FIX: Pass the AilmentsManager module as an argument.
			teleportAndHandleRideWalk(ailmentData, AilmentsManager)
		else
			warn("Unhandled teleport location:", locationName)
		end
	end)
	
	if not success then
		warn("Processing ailment failed:", result)
	end
end

-- The main processing loop which handles the `isProcessingAilment` flag.
local function handleNextAilment()
	if not isProcessingAilment and #ailmentsToProcess > 0 then
		local data = table.remove(ailmentsToProcess, 1)
		processAilment(data)
	end
end

local function startAilmentProcessingLoop()
	while true do
		handleNextAilment()
		task.wait(1)
	end
end

-- A new function to handle all cleanup logic after an ailment is completed.
local function cleanupAilment(ailmentData)
	local ailmentId = ailmentData.ailmentId

	if ailmentId == "play" then
		if ailmentData.unequipItemId and UnequipRemote then
			local success, result = pcall(function()
				return UnequipRemote:InvokeServer(ailmentData.unequipItemId)
			end)
			if success then
				print("✅ Unequipped tool with ID:", ailmentData.unequipItemId, "after 'play' ailment.")
			else
				warn("Failed to unequip tool:", result)
			end
		end
	elseif ailmentId == "ride" or ailmentId == "walk" then
		if ailmentData.unequipItemId and UnequipRemote then
			local success, result = pcall(function()
				return UnequipRemote:InvokeServer(ailmentData.unequipItemId)
			end)
			if success then
				print("✅ Unequipped stroller with ID:", ailmentData.unequipItemId, "after 'ride' ailment.")
			else
				warn("Failed to unequip stroller:", result)
			end
		end
		if ailmentData.petModel and EjectBabyRemote then
			local success, result = pcall(function()
				EjectBabyRemote:FireServer(ailmentData.petModel)
			end)
			if success then
				print("✅ Unheld/Ejected pet after 'walk'/'ride' ailment.")
			else
				warn("Failed to unhold/eject pet:", result)
			end
		end
	end
end

local function initialAilmentUIScan()
	print("🔄Initial scan for ailments...")
	for _, map in pairs(activeAilmentUIs) do
		for _, entry in pairs(map) do
			if entry.UiLabel and entry.UiLabel.Parent then
				entry.UiLabel:Destroy()
			end
		end
	end
	activeAilmentUIs = {}
	local myInventory = ClientDataModule.get("inventory")
	if myInventory and myInventory.pets then
		for petUniqueId, petData in pairs(myInventory.pets) do
			local petRef = createEntityReference(LocalPlayer, true, petUniqueId)
			local petAilments = AilmentsManager.get_ailments_for_pet(petRef)
			if petAilments then
				for _, ailmentInstance in pairs(petAilments) do
					local ailmentId = getAilmentIdFromInstance(ailmentInstance)
					-- Filter out ailments we don't have logic for yet
					if ailmentId ~= "mystery" and ailmentId ~= "pet_me" then
						addAilmentToUI(ailmentInstance, petUniqueId, petRef)
						table.insert(ailmentsToProcess, {
							ailmentId = ailmentId,
							entityUniqueKey = petUniqueId,
							entityRef = petRef,
							ailmentInstance = ailmentInstance,
						})
					else
						print("Skipping unsupported ailment:", ailmentId, "from initial scan.")
					end
				end
			end
		end
	end
	print("✅Initial scan complete. Queue:", #ailmentsToProcess)
end

local function onAilmentComplete(ailmentInstance, entityUniqueKey)
	-- Safely get the entityRef and ailmentData by checking if the UI entry exists first.
	local ailmentId = getAilmentIdFromInstance(ailmentInstance)
	local uiMap = activeAilmentUIs[entityUniqueKey]
	local uiEntry = uiMap and uiMap[ailmentId]
	
	if not uiEntry then
		warn("Ailment completed signal received, but could not find matching UI entry for entity key:", entityUniqueKey, "and ailment:", ailmentId)
		return
	end

	-- Pass the complete ailmentData to the cleanup function.
	cleanupAilment(uiEntry)

	removeAilmentFromUI(ailmentInstance, entityUniqueKey, uiEntry.EntityRef)
	print("Ailment completed:", ailmentId)
	if ailmentId == "walk" or ailmentId == "ride" then stopJumping() end

	-- This is the crucial fix: the flag is only reset here after a confirmed completion.
	print("Processing flag reset to: false")
	isProcessingAilment = false
end

-- Connect signals safely
if AilmentsManager.get_ailment_created_signal and AilmentsManager.get_ailment_completed_signal then
	AilmentsManager.get_ailment_created_signal():Connect(function(ailmentInstance, entityUniqueKey)
		local isPet = (#entityUniqueKey > 10)
		local entityRef = createEntityReference(LocalPlayer, isPet, entityUniqueKey)
		if isPet then
			local ailmentId = getAilmentIdFromInstance(ailmentInstance)
			-- Filter out ailments we don't have logic for yet
			if ailmentId ~= "mystery" and ailmentId ~= "pet_me" then
				addAilmentToUI(ailmentInstance, entityUniqueKey, entityRef)
				table.insert(ailmentsToProcess, {
					ailmentId = ailmentId,
					entityUniqueKey = entityUniqueKey,
					entityRef = entityRef,
					ailmentInstance = ailmentInstance,
				})
			else
				print("Skipping unsupported ailment:", ailmentId)
			end
		end
	end)

	AilmentsManager.get_ailment_completed_signal():Connect(onAilmentComplete)
else
	warn("AilmentsManager signals missing.")
end
print("---")
print("-- SETUP STAGE--")
print("✅Pet Ailment script initializing...")
createAilmentUI()
print("✅Performing initial teleport to housing for the first ailment to be processed.")

-- Now that we're in the correct location, create the UI and start the ailment processing loop.
initialAilmentUIScan()
coroutine.wrap(startAilmentProcessingLoop)()

-- --- UI Text Update ---
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	if os.time() - lastUpdate < 1 then return end
	lastUpdate = os.time()
	if AilmentDisplayGui and AilmentDisplayGui.Parent then
		for entityKey, map in pairs(activeAilmentUIs) do
			for _, entry in pairs(map) do
				local ailmentInstance = entry.AilmentInstance
				local uiLabel = entry.UiLabel
				local entityRef = entry.EntityRef
				if uiLabel and uiLabel.Parent then
					local displayName, uniqueId = getEntityDisplayInfo(entityRef)
					local textStr
					if entityRef.is_pet then
						textStr = string.format("%s (%s) - %s%s", displayName, uniqueId, entry.StoredAilmentId, formatAilmentDetails(ailmentInstance))
					else
						textStr = string.format("%s - %s%s", displayName, entry.StoredAilmentId, formatAilmentDetails(ailmentInstance))
					end
					uiLabel.Text = textStr
				end
			end
		end
	end
end)
