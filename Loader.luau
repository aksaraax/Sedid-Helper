--!strict
type KeyAuthConfig = {
	Name: string,
	OwnerID: string,
	Secret: string,
	Version: string,
}

type HttpResponse = {
	Body: string,
	StatusCode: number,
	Success: boolean,
}

type KeyAuthResponse = {
	success: boolean,
	message: string?,
	sessionid: string?,
	info: {
		username: string?,
		subscriptions: {{subscription: string, expiry: string}}?,
	}?,
}

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local CONFIG: KeyAuthConfig = {
	Name = "CDID Helper",
	OwnerID = "i7s7snUTi1",      
	Secret = "f8e7b5c5c7e1a3f7e06b57641b4821aef133de3e4f345ffb9e51610332c357fa",     
	Version = "1.0",
}

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/aksaraax/Sedid-Helper/main/CDID_Helper.luau"

local function getHWID(): string
	local hwid: string? = nil
	
	pcall(function()
		if (gethwid :: any) then
			hwid = (gethwid :: () -> string)()
		end
	end)
	
	if hwid then return hwid end
	
	pcall(function()
		hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
	end)
	
	if hwid then return hwid end
	
	return tostring(Players.LocalPlayer.UserId)
end

local function httpRequest(options: {Url: string, Method: string}): HttpResponse?
	local requestFunc: any = nil
	
	pcall(function()
		if (syn :: any) and (syn :: any).request then
			requestFunc = (syn :: any).request
		elseif (http :: any) and (http :: any).request then
			requestFunc = (http :: any).request
		elseif (http_request :: any) then
			requestFunc = http_request :: any
		elseif (request :: any) then
			requestFunc = request :: any
		end
	end)
	
	if not requestFunc then
		return nil
	end
	
	local success, response = pcall(requestFunc, options)
	
	if success and response then
		return response :: HttpResponse
	end
	
	return nil
end

local function encodeParams(params: {[string]: string}): string
	local result: {string} = {}
	
	for key, value in params do
		table.insert(result, `{key}={value}`)
	end
	
	return table.concat(result, "&")
end

local function showNotification(title: string, text: string, duration: number?): ()
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 3,
		})
	end)
end

local KeyAuth = {
	initialized = false,
	sessionId = nil :: string?,
	hwid = getHWID(),
}

function KeyAuth:Init(): (boolean, string)
	local body = encodeParams({
		type = "init",
		ver = CONFIG.Version,
		name = CONFIG.Name,
		ownerid = CONFIG.OwnerID,
	})
	
	local requestFunc: any = nil
	pcall(function()
		if (syn :: any) and (syn :: any).request then
			requestFunc = (syn :: any).request
		elseif (http :: any) and (http :: any).request then
			requestFunc = (http :: any).request
		elseif (http_request :: any) then
			requestFunc = http_request :: any
		elseif (request :: any) then
			requestFunc = request :: any
		end
	end)
	
	if not requestFunc then
		return false, "No HTTP function"
	end
	
	local success, response = pcall(requestFunc, {
		Url = "https://keyauth.win/api/1.2/",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded",
		},
		Body = body,
	})
	
	if success and response and response.Body then
		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		
		if decodeSuccess and data.success then
			self.sessionId = data.sessionid
			self.initialized = true
			return true, "Initialized"
		else
			return false, (data and data.message) or "Init failed"
		end
	end
	
	return false, "Request failed"
end

function KeyAuth:License(key: string): (boolean, string)
	if not self.initialized then
		local initSuccess, initMsg = self:Init()
		if not initSuccess then
			return false, initMsg
		end
	end
	
	local body = encodeParams({
		type = "license",
		key = key,
		hwid = self.hwid,
		sessionid = self.sessionId or "",
		name = CONFIG.Name,
		ownerid = CONFIG.OwnerID,
	})
	
	local requestFunc: any = nil
	pcall(function()
		if (syn :: any) and (syn :: any).request then
			requestFunc = (syn :: any).request
		elseif (http :: any) and (http :: any).request then
			requestFunc = (http :: any).request
		elseif (http_request :: any) then
			requestFunc = http_request :: any
		elseif (request :: any) then
			requestFunc = request :: any
		end
	end)
	
	if not requestFunc then
		return false, "No HTTP function"
	end
	
	local success, response = pcall(requestFunc, {
		Url = "https://keyauth.win/api/1.2/",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded",
		},
		Body = body,
	})
	
	if success and response and response.Body then
		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		
		if decodeSuccess and data.success then
			return true, "Licensed"
		else
			return false, (data and data.message) or "License failed"
		end
	end
	
	return false, "Request failed"
end

local function getScriptKey(): string?
	local key: string? = nil
	
	pcall(function()
		if (script_key :: any) then
			key = script_key :: string
		elseif _G.script_key then
			key = _G.script_key :: string
		elseif (getgenv :: any) then
			local env = (getgenv :: () -> {[string]: any})()
			if env.script_key then
				key = env.script_key :: string
			end
		end
	end)
	
	return key
end

local function authenticate(): boolean
	local key = getScriptKey()
	
	if not key or key == "" or key == "YOUR-KEY-HERE" then
		warn("[CDID Helper] No valid key provided!")
		showNotification("CDID Helper", "Please set script_key before running", 5)
		return false
	end
	
	showNotification("CDID Helper", "Authenticating...", 2)
	
	local success, result = KeyAuth:License(key)
	
	if success then
		showNotification("CDID Helper", "Authenticated! Loading...", 2)
		return true
	else
		warn(`[CDID Helper] Auth Failed: {result}`)
		showNotification("CDID Helper", `Auth Failed: {result}`, 5)
		return false
	end
end

if not authenticate() then
	return
end

local loadSuccess, loadError = pcall(function()
	loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
end)

if not loadSuccess then
	warn(`[CDID Helper] Failed to load: {loadError}`)
	showNotification("CDID Helper", "Failed to load script!", 5)
end
