local frame
local next = next
local clientNode, serverNode

local serverHooksCache = serverHooksCache or {}
local clientHooksCache = clientHooksCache or {}

local backgroundColor = Color(39,43,48)

--[[
	Remove all the unwanted values from a table.
	This functions is specific to the Garry's Mod hook table.
]]
local function SearchTable(searchedTable, searchData)
	-- I was inspired to name these variables
	local z = {}
	for a, b in SortedPairs(searchedTable) do
		for c, d in pairs(b) do
			if not string.find(string.lower(tostring(c)), searchData) then continue end
			z[a] = {[c] = d}
		end
		if not string.find(string.lower(a), searchData) then continue end
		z[a] = b
	end
	return z
end

--[[
This table contains alllll the values of the game hooks,
including server/client hooks & function data.
Here is the structure:
-- Server
	-- Hook Name
		-- Hook identifier (addon)
			-- function: xx
			-- source: xx
			-- linedefined: xx
-- Client
	-- Hook Name
		-- Hook identifier (addon)
			-- function: xx
			-- source: xx
			-- linedefined: xx
]]
local finalHooks = {}

local function CleanupData(searchData)
	clientNode:Clear()
	serverNode:Clear()

	-- Do not erease the cached values
	local clientHooks, serverHooks
	clientHooks = clientHooksCache or {}
	serverHooks = serverHooksCache or {}

	if searchData then
		clientHooks = SearchTable(clientHooksCache, searchData)
		serverHooks = SearchTable(serverHooksCache, searchData)
		clientNode:SetExpanded(true)
		serverNode:SetExpanded(true)
	end

	-- Pretty much the same code as the server
	local hooks = {}
	for hookName, hookChild in SortedPairs(clientHooks) do
		local childs = {}
		for childName, childFunction in pairs(hookChild) do
			local functionInfo = debug.getinfo(childFunction, "S")

			childName, childFunction = tostring(childName), tostring(childFunction)
			childs[childName] = {
				["function"] = childFunction,
				["source"] = functionInfo["source"],
				["linedefined"] = functionInfo["linedefined"],
			}
		end
		hooks[hookName] = childs
	end

	-- Already cleaned up on the server side
	finalHooks["Client"] = hooks
	finalHooks["Server"] = serverHooks
end

local function PopulateData()
	for hookSide, hookValues in pairs(finalHooks) do
		for hookName, hookIdentifier in SortedPairs(hookValues) do
			if hookSide == "Client" then
				local hookNameNode = clientNode:AddNode(hookName, "icon16/database_key.png")
				for addonHookName, functionData in pairs(hookIdentifier) do
					local addonHookNameNode = hookNameNode:AddNode(addonHookName, "icon16/database_gear.png")
					addonHookNameNode:AddNode("Function: " .. functionData["function"], "icon16/page_white_flash.png")
					addonHookNameNode:AddNode("Source: " .. functionData["source"], "icon16/page_white_flash.png")
					addonHookNameNode:AddNode("Line: " .. functionData["linedefined"], "icon16/page_white_flash.png")
				end
			end
			if hookSide == "Server" then
				local hookNameNode = serverNode:AddNode(hookName, "icon16/database_key.png")
				for addonHookName, functionData in pairs(hookIdentifier) do
					local addonHookNameNode = hookNameNode:AddNode(addonHookName, "icon16/database_gear.png")
					addonHookNameNode:AddNode("Function: " .. functionData["function"], "icon16/page_white_flash.png")
					addonHookNameNode:AddNode("Source: " .. functionData["source"], "icon16/page_white_flash.png")
					addonHookNameNode:AddNode("Line: " .. functionData["linedefined"], "icon16/page_white_flash.png")
				end
			end
		end
	end
end

local function DrawFrame()
	if IsValid(frame) then frame:Remove() end
	local scrw, scrh = ScrW(),ScrH()

	-- == FRAME ==
	frame = vgui.Create("DFrame")
	frame:SetSize(800, 800)
	frame:SetDraggable(true)
	frame:Center()
	frame:SetTitle("Hooker - By ItsJustMiaouss")
	frame:MakePopup()
	frame.Paint = function()
		surface.SetDrawColor(backgroundColor)
		surface.DrawRect(0, 0, scrw, scrh)
	end

	local topPanel = vgui.Create("DPanel", frame)
	topPanel:Dock(TOP)

	local dtree = vgui.Create("DTree", frame)
	dtree:Dock(FILL)

	-- == NODES ==
	clientNode = dtree:AddNode("Client-Side Hooks", "icon16/database.png")
	serverNode = dtree:AddNode("Server-Side Hooks", "icon16/database.png")

	-- == LOADING HOOKS ==
	if next(serverHooksCache) == nil or next(clientHooksCache) == nil then
		net.Start("Hooker:RefreshHooks")
		net.SendToServer()
	end
	CleanupData()
	PopulateData()

	-- == REFRESH BUTTON ==
	local refreshBtn = vgui.Create("DButton", topPanel)
	refreshBtn:Dock(LEFT)
	refreshBtn:SetText("Refresh")
	refreshBtn.DoClick = function()
		net.Start("Hooker:RefreshHooks")
		net.SendToServer()
	end

	-- == SEARCH ==
	local searchBox = vgui.Create("DTextEntry", topPanel)
	searchBox:SetPlaceholderText("Search...")
	searchBox:Dock(RIGHT)
	searchBox:SetSize(200, 10)
	searchBox.OnEnter = function(self)
		value = self:GetValue()
		if value == "" then value = nil end
		CleanupData(value)
		PopulateData()
	end
end

net.Receive("Hooker:ServerHooksCallback", function()
	local byte = net.ReadUInt(16)
	local compressedData = net.ReadData(byte)
	local netDecompressed = util.Decompress(compressedData)

	serverHooksCache = util.JSONToTable(netDecompressed)
	clientHooksCache = hook.GetTable()
	CleanupData()
	PopulateData()
end)

net.Receive("Hooker:OpenClientMenu", function() DrawFrame() end)
