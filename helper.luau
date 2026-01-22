--!strict
type CooldownMap = {[string]: number}
type PlayerInfo = {
	Name: string,
	DisplayName: string,
	Health: number,
	MaxHealth: number,
	Cash: number?,
}

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/aksaraax/Sedid-Helper/main/WindUI/main.luau"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local NetworkContainer = ReplicatedStorage:WaitForChild("NetworkContainer") :: Folder
local RemoteEvents = NetworkContainer:WaitForChild("RemoteEvents") :: Folder
local RemoteFunctions = NetworkContainer:WaitForChild("RemoteFunctions") :: Folder

local WashRemote = RemoteEvents:WaitForChild("Wash") :: RemoteEvent
local DealershipRemote = RemoteFunctions:WaitForChild("Dealership") :: RemoteFunction
local FuelRemote = RemoteEvents:WaitForChild("Fuel") :: RemoteEvent
local ModificationRemote = RemoteEvents:WaitForChild("ModificationRequest") :: RemoteEvent
local ChangeOilRemote = RemoteEvents:WaitForChild("ChangeOil") :: RemoteEvent

local Cooldowns: CooldownMap = {
	Dealer = 0,
	Wash = 0,
	Fuel = 0,
	Modification = 0,
	Oil = 0,
}

local CooldownTimes: CooldownMap = {
	Dealer = 5,
	Wash = 10,
	Fuel = 5,
	Modification = 5,
	Oil = 10,
}

local FuelTypes: {string} = {
	"Pertalite", "Pertamax", "Turbo", "Solar", "Dex",
	"SuperRON92", "VPowerRON95", "VPowerNitroRON98", "VPowerDieselCN51", "Electric"
}

local FuelPrices: {[string]: number} = {
	["Pertalite"] = 10000,
	["Pertamax"] = 12200,
	["Turbo"] = 13100,
	["Solar"] = 6800,
	["Dex"] = 14200,
	["SuperRON92"] = 12680,
	["VPowerRON95"] = 13260,
	["VPowerNitroRON98"] = 13480,
	["VPowerDieselCN51"] = 14410,
	["Electric"] = 1455,
}

local DealerList: {string} = {
	"77", "Audi", "BMW", "Bandung", "Daihatsu", "Honda", "Hyundai", 
	"KIA", "Komersial", "Lexus", "Mazda", "MercedesBenz", "Mitsubishi", 
	"Nissan", "Otnas", "Premium", "Suzuki", "Toyota", "VW", "Wuling"
}

local DealerNameMap: {[string]: {string}} = {
	["77"] = {"Dealer 77", "Dealer77", "77"},
	["Audi"] = {"Dealer Audi", "DealerAudi", "Audi"},
	["BMW"] = {"Dealer BMW", "DealerBMW", "BMW"},
	["Bandung"] = {"Dealer Bandung", "DealerBandung", "Bandung"},
	["Daihatsu"] = {"Dealer Daihatsu", "DealerDaihatsu", "Daihatsu"},
	["Honda"] = {"Dealer Honda", "DealerHonda", "Honda"},
	["Hyundai"] = {"Dealer Hyundai", "DealerHyundai", "Hyundai"},
	["KIA"] = {"Dealer KIA", "DealerKIA", "KIA"},
	["Komersial"] = {"Dealer Komersial", "DealerKomersial", "Komersial"},
	["Lexus"] = {"Dealer Lexus", "DealerLexus", "Lexus"},
	["Mazda"] = {"Dealer Mazda", "DealerMazda", "Mazda"},
	["MercedesBenz"] = {"Dealer MMercedes", "Dealer Mercedes", "DealerMercedes", "MercedesBenz", "Mercedes"},
	["Mitsubishi"] = {"Dealer Mitsubishi", "DealerMitsubishi", "Mitsubishi"},
	["Nissan"] = {"Dealer Nissan", "DealerNissan", "Nissan"},
	["Otnas"] = {"Dealer Otnas", "DealerOtnas", "Otnas"},
	["Premium"] = {"Dealer Premium", "DealerPremium", "Premium"},
	["Suzuki"] = {"Dealer Suzuki", "DealerSuzuki", "Suzuki"},
	["Toyota"] = {"Dealer Toyota", "DealerToyota", "Toyota"},
	["VW"] = {"Dealer VW", "DealerVW", "VW"},
	["Wuling"] = {"Dealer Wuling", "DealerWuling", "Wuling"},
}

local function randomDelay(min: number, max: number): number
	local delayTime = min + (math.random() * (max - min))
	task.wait(delayTime)
	return delayTime
end

local function canUse(feature: string): (boolean, number)
	local now = tick()
	local lastUsed = Cooldowns[feature] or 0
	local cooldownTime = CooldownTimes[feature] or 5
	
	if now - lastUsed < cooldownTime then
		local remaining = math.ceil(cooldownTime - (now - lastUsed))
		return false, remaining
	end
	
	return true, 0
end

local function markUsed(feature: string): ()
	Cooldowns[feature] = tick()
end

local function findDealerPrompt(dealerName: string): ProximityPrompt?
	local searchNames = DealerNameMap[dealerName] or {dealerName, `Dealer {dealerName}`, `Dealer{dealerName}`}
	
	local mapFolder = workspace:FindFirstChild("Map")
	local etcFolder = workspace:FindFirstChild("Etc")
	
	local searchLocations: {Instance?} = {
		mapFolder and mapFolder:FindFirstChild("Building"),
		etcFolder and etcFolder:FindFirstChild("Dealership"),
		mapFolder,
		workspace,
	}
	
	for _, location in searchLocations do
		if location then
			for _, searchName in searchNames do
				local dealer = location:FindFirstChild(searchName, true)
				if dealer then
					for _, obj in dealer:GetDescendants() do
						if obj:IsA("ProximityPrompt") then
							return obj
						end
					end
				end
			end
			
			for _, obj in location:GetDescendants() do
				if obj:IsA("ProximityPrompt") then
					local fullName = obj:GetFullName():lower()
					for _, searchName in searchNames do
						if fullName:find(searchName:lower()) then
							return obj
						end
					end
				end
			end
		end
	end
	
	return nil
end

local function openDealerUI(dealerName: string): (boolean, string)
	local canProceed, remaining = canUse("Dealer")
	if not canProceed then
		return false, `Cooldown: {remaining}s`
	end
	
	randomDelay(0.3, 0.8)
	
	local prompt = findDealerPrompt(dealerName)
	
	if prompt then
		if fireproximityprompt then
			fireproximityprompt(prompt)
			markUsed("Dealer")
			return true, "Opened"
		else
			prompt:InputHoldBegin()
			task.wait(prompt.HoldDuration + 0.1)
			prompt:InputHoldEnd()
			markUsed("Dealer")
			return true, "Opened"
		end
	end
	
	pcall(function()
		DealershipRemote:InvokeServer(dealerName)
	end)
	
	local existingUI = PlayerGui:FindFirstChild("Dealership") :: ScreenGui?
	if existingUI then
		local container = existingUI:FindFirstChild("Container") :: Frame?
		if container then
			container.Visible = true
		end
		existingUI.Enabled = true
		
		local dealerList = existingUI:FindFirstChild("Dealerlist", true) :: Frame?
		if dealerList then
			local dealerBtn = dealerList:FindFirstChild(dealerName) :: GuiButton?
			if dealerBtn and dealerBtn:IsA("GuiButton") and getconnections then
				for _, conn in getconnections(dealerBtn.MouseButton1Click) do
					conn:Fire()
				end
			end
		end
		
		markUsed("Dealer")
		return true, "Opened"
	end
	
	return false, "Not found"
end

local function washCar(): (boolean, string)
	local canProceed, remaining = canUse("Wash")
	if not canProceed then
		return false, `Cooldown: {remaining}s`
	end
	
	randomDelay(0.5, 1.2)
	
	local success = pcall(function()
		WashRemote:FireServer()
	end)
	
	if success then
		markUsed("Wash")
	end
	
	return success, if success then "Done" else "Failed"
end

local function findFuelPrompt(fuelType: string): ProximityPrompt?
	local fuelFiller = workspace:FindFirstChild("Etc")
	if not fuelFiller then return nil end
	
	local car = fuelFiller:FindFirstChild("Car")
	if not car then return nil end
	
	local fillerFolder = car:FindFirstChild("FuelFiller")
	if not fillerFolder then return nil end
	
	for _, obj in fillerFolder:GetDescendants() do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			local objectText = obj.ObjectText:lower()
			local searchType = fuelType:lower()
			
			if objectText:find(searchType) or searchType:find(objectText) then
				return obj
			end
		end
	end
	
	for _, obj in fillerFolder:GetDescendants() do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			return obj
		end
	end
	
	return nil
end

local function refillFuel(fuelType: string, amount: number?): (boolean, string)
	local canProceed, remaining = canUse("Fuel")
	if not canProceed then
		return false, `Cooldown: {remaining}s`
	end
	
	randomDelay(0.3, 0.8)
	
	local prompt = findFuelPrompt(fuelType)
	
	if prompt then
		if fireproximityprompt then
			fireproximityprompt(prompt)
			markUsed("Fuel")
			return true, `Filled with {prompt.ObjectText}`
		else
			prompt:InputHoldBegin()
			task.wait(prompt.HoldDuration + 0.1)
			prompt:InputHoldEnd()
			markUsed("Fuel")
			return true, `Filled with {prompt.ObjectText}`
		end
	end
	
	local success = pcall(function()
		FuelRemote:FireServer(fuelType, amount or 100)
	end)
	
	if success then
		markUsed("Fuel")
		return true, `Sent {fuelType} request`
	end
	
	return false, "Prompt not found - drive to SPBU first"
end

local function getModificationPosition(): Vector3?
	local modPart = workspace:FindFirstChild("ModificationPart")
	if not modPart then return nil end
	
	local hitbox = modPart:FindFirstChild("Hitbox")
	if hitbox and hitbox:IsA("BasePart") then
		return hitbox.Position + Vector3.new(0, 3, 0)
	end
	
	local test55 = modPart:FindFirstChild("test55")
	if test55 then
		local inner = test55:FindFirstChild("test55")
		if inner and inner:IsA("BasePart") then
			return inner.Position + Vector3.new(0, 3, 0)
		end
	end
	
	return nil
end

local function openModification(): (boolean, string)
	local canProceed, remaining = canUse("Modification")
	if not canProceed then
		return false, `Cooldown: {remaining}s`
	end
	
	local char = LocalPlayer.Character
	if not char then return false, "No character" end
	
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then return false, "Invalid character" end
	
	local seatPart = humanoid.SeatPart
	if seatPart then
		return false, "Exit vehicle first"
	end
	
	local targetPos = getModificationPosition()
	if not targetPos then
		return false, "Modification zone not found"
	end
	
	randomDelay(0.3, 0.5)
	
	hrp.CFrame = CFrame.new(targetPos)
	markUsed("Modification")
	
	return true, "Teleported to Modification"
end

local function changeOil(): (boolean, string)
	local canProceed, remaining = canUse("Oil")
	if not canProceed then
		return false, `Cooldown: {remaining}s`
	end
	
	randomDelay(0.3, 0.8)
	
	local success = pcall(function()
		ChangeOilRemote:FireServer()
	end)
	
	if success then
		markUsed("Oil")
	end
	
	return success, if success then "Oil changed" else "Failed"
end

local function getPlayerInfo(): PlayerInfo
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	
	local info: PlayerInfo = {
		Name = LocalPlayer.Name,
		DisplayName = LocalPlayer.DisplayName,
		Health = if humanoid then math.floor(humanoid.Health) else 0,
		MaxHealth = if humanoid then math.floor(humanoid.MaxHealth) else 100,
		Cash = nil,
	}
	
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
		if cash and cash:IsA("ValueBase") then
			info.Cash = cash.Value :: number
		end
	end
	
	return info
end

local function getCooldownStatus(): {[string]: string}
	local now = tick()
	local status: {[string]: string} = {}
	
	for feature, lastUsed in Cooldowns do
		local cooldownTime = CooldownTimes[feature] or 5
		local remaining = cooldownTime - (now - lastUsed)
		
		status[feature] = if remaining > 0 then `{math.ceil(remaining)}s` else "Ready"
	end
	
	return status
end

local Window = WindUI:CreateWindow({
	Title = "CDID Helper    ",
	Folder = "CDIDHelper",
	Icon = "rbxassetid://86369407133802",
	NewElements = true,
	OpenButton = {
		Title = "CDID",
		CornerRadius = UDim.new(0.5, 0),
		StrokeThickness = 2,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Scale = 0.5,
		Color = ColorSequence.new(
			Color3.fromHex("#FFFFFF"),
			Color3.fromHex("#CCCCCC")
		)
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

Window:Tag({
	Title = "v0.001",
	Icon = "github",
	Color = Color3.fromHex("#1c1c1c"),
	Border = true,
})

local InfoSection = Window:Section({
	Title = "Info",
})

local MainSection = Window:Section({
	Title = "Features",
})

local InfoTab = InfoSection:Tab({
	Title = "Player Info",
	Icon = "solar:user-bold",
	IconColor = Color3.fromHex("#FFFFFF"),
	IconShape = "Square",
	Border = true,
})

InfoTab:Section({
	Title = "Player",
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

InfoTab:Button({
	Title = "Refresh Info",
	Desc = "Update player information",
	Callback = function()
		local info = getPlayerInfo()
		local cashText = if info.Cash then `\nCash: {info.Cash}` else ""
		
		WindUI:Notify({
			Title = info.DisplayName,
			Content = `Health: {info.Health}/{info.MaxHealth}{cashText}`,
			Duration = 3,
		})
	end
})

InfoTab:Space()

InfoTab:Section({
	Title = "Server",
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

InfoTab:Button({
	Title = "Server Info",
	Desc = "Show server information",
	Callback = function()
		local placeId = game.PlaceId
		local playerCount = #Players:GetPlayers()
		
		WindUI:Notify({
			Title = "Server Info",
			Content = `Players: {playerCount}\nPlaceId: {placeId}`,
			Duration = 3,
		})
	end
})

InfoTab:Space()

InfoTab:Section({
	Title = "Cooldown Status",
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

InfoTab:Button({
	Title = "Check Cooldowns",
	Desc = "View remaining cooldown times",
	Callback = function()
		local status = getCooldownStatus()
		local lines: {string} = {}
		
		for feature, time in status do
			table.insert(lines, `{feature}: {time}`)
		end
		
		WindUI:Notify({
			Title = "Cooldowns",
			Content = table.concat(lines, "\n"),
			Duration = 3,
		})
	end
})

local DealerTab = MainSection:Tab({
	Title = "Dealership",
	Icon = "solar:shop-bold",
	IconColor = Color3.fromHex("#FFFFFF"),
	IconShape = "Square",
	Border = true,
})

DealerTab:Section({
	Title = "Open Dealer",
	Desc = `Cooldown: {CooldownTimes.Dealer}s`,
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

local selectedDealer: string? = nil

DealerTab:Dropdown({
	Title = "Pilih Dealer",
	Values = DealerList,
	Callback = function(selected: string)
		selectedDealer = selected
	end
})

DealerTab:Space()

DealerTab:Button({
	Title = "Open Dealer",
	Desc = "Buka dealer yang dipilih",
	Callback = function()
		if not selectedDealer then
			WindUI:Notify({
				Title = "Error",
				Content = "Pilih dealer terlebih dahulu",
				Duration = 2,
			})
			return
		end
		
		WindUI:Notify({
			Title = "Processing",
			Content = `Opening {selectedDealer}...`,
			Duration = 1,
		})
		
		local success, msg = openDealerUI(selectedDealer)
		WindUI:Notify({
			Title = if success then selectedDealer else "Failed",
			Content = msg,
			Duration = 2,
		})
	end
})

local WashTab = MainSection:Tab({
	Title = "Car Wash",
	Icon = "solar:washing-machine-bold",
	IconColor = Color3.fromHex("#FFFFFF"),
	IconShape = "Square",
	Border = true,
})

WashTab:Section({
	Title = "Quick Wash",
	Desc = `Cooldown: {CooldownTimes.Wash}s`,
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

WashTab:Button({
	Title = "Wash Car",
	Desc = "Cuci mobil sekarang",
	Callback = function()
		WindUI:Notify({
			Title = "Processing",
			Content = "Washing...",
			Duration = 1,
		})
		
		local success, msg = washCar()
		WindUI:Notify({
			Title = if success then "Success" else "Failed",
			Content = msg,
			Duration = 2,
		})
	end
})

local FuelTab = MainSection:Tab({
	Title = "Fuel",
	Icon = "solar:gas-station-bold",
	IconColor = Color3.fromHex("#FFFFFF"),
	IconShape = "Square",
	Border = true,
})

FuelTab:Section({
	Title = "Isi Bensin",
	Desc = `Cooldown: {CooldownTimes.Fuel}s`,
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

local selectedFuel: string? = nil

FuelTab:Dropdown({
	Title = "Pilih Bahan Bakar",
	Values = FuelTypes,
	Callback = function(selected: string)
		selectedFuel = selected
		local price = FuelPrices[selected] or 0
		WindUI:Notify({
			Title = selected,
			Content = `Harga: Rp{price}/L`,
			Duration = 2,
		})
	end
})

FuelTab:Space()

FuelTab:Button({
	Title = "Isi Full Tank",
	Desc = "Isi bensin sampai penuh",
	Callback = function()
		if not selectedFuel then
			WindUI:Notify({
				Title = "Error",
				Content = "Pilih bahan bakar terlebih dahulu",
				Duration = 2,
			})
			return
		end
		
		WindUI:Notify({
			Title = "Processing",
			Content = `Mengisi {selectedFuel}...`,
			Duration = 1,
		})
		
		local success, msg = refillFuel(selectedFuel, 100)
		WindUI:Notify({
			Title = if success then "Success" else "Failed",
			Content = msg,
			Duration = 2,
		})
	end
})

local ModTab = MainSection:Tab({
	Title = "Modification",
	Icon = "solar:settings-bold",
	IconColor = Color3.fromHex("#FFFFFF"),
	IconShape = "Square",
	Border = true,
})

ModTab:Section({
	Title = "Vehicle Modification",
	Desc = `Cooldown: {CooldownTimes.Modification}s`,
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

ModTab:Button({
	Title = "Open Modification",
	Desc = "Buka menu modifikasi kendaraan",
	Callback = function()
		WindUI:Notify({
			Title = "Processing",
			Content = "Opening modification...",
			Duration = 1,
		})
		
		local success, msg = openModification()
		WindUI:Notify({
			Title = if success then "Success" else "Failed",
			Content = msg,
			Duration = 2,
		})
	end
})

ModTab:Space()

ModTab:Section({
	Title = "Maintenance",
	Desc = `Cooldown: {CooldownTimes.Oil}s`,
	TextSize = 14,
	FontWeight = Enum.FontWeight.Medium,
})

ModTab:Button({
	Title = "Change Oil",
	Desc = "Ganti oli kendaraan",
	Callback = function()
		WindUI:Notify({
			Title = "Processing",
			Content = "Changing oil...",
			Duration = 1,
		})
		
		local success, msg = changeOil()
		WindUI:Notify({
			Title = if success then "Success" else "Failed",
			Content = msg,
			Duration = 2,
		})
	end
})

task.spawn(function()
	task.wait(1)
	WindUI:Notify({
		Title = "CDID Helper",
		Content = "Ready",
		Duration = 3,
	})
end)

return Window
