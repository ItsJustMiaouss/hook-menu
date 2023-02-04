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

-- These tables contains alllll the values of the game hooks
-- local finalServerHooks = {}
-- local finalClientHooks = {}

local function RefreshData(searchData)
	clientNode:Clear()
	serverNode:Clear()

	-- Do not erease the cached values
	local clientHooks, serverHooks
	clientHooks = clientHooksCache or {}
	serverHooks = serverHooksCache or {}

	if searchData then clientHooks = SearchTable(clientHooksCache, searchData) end
	if searchData then serverHooks = SearchTable(serverHooksCache, searchData) end

	for hookName, hookChild in SortedPairs(clientHooks) do
		local hookNameNode = clientNode:AddNode(hookName, "icon16/database_key.png")

		for childName, childFunction in pairs(hookChild) do
			local childNameNode = hookNameNode:AddNode(tostring(childName), "icon16/database_gear.png")
			local func = childNameNode:AddNode(tostring(childFunction), "icon16/page_white_flash.png")
			func:AddNode(debug.getinfo(childFunction, "S")["source"])
			func:AddNode("Line: " .. debug.getinfo(childFunction, "S")["linedefined"])
			-- func:AddNode("Args: " .. GetFunctionArgs(childFunction))
		end
	end

	for hookName, hookChild in SortedPairs(serverHooks) do
		local hookNameNode = serverNode:AddNode(hookName, "icon16/database_key.png")

		for childName, childFunction in pairs(hookChild) do
			local childNameNode = hookNameNode:AddNode(tostring(childName), "icon16/database_gear.png")
			childNameNode:AddNode(tostring(childFunction), "icon16/page_white_flash.png")
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
	else
		RefreshData()
	end

	-- == REFRESH BUTTON ==
	local refreshBtn = vgui.Create("DButton", topPanel)
	refreshBtn:Dock(LEFT)
	refreshBtn:SetText("Refresh")
	refreshBtn.DoClick = function()
		net.Start("Hooker:RefreshHooks")
		net.SendToServer()
	end

	-- local clientHooks = hook.GetTable()
	-- RefreshData(clientHooks, serverHooks, clientNode, serverNode)

	-- == SEARCH ==
	local searchBox = vgui.Create("DTextEntry", topPanel)
	searchBox:SetPlaceholderText("Search...")
	searchBox:Dock(RIGHT)
	searchBox:SetSize(200, 10)
	searchBox.OnEnter = function(self)
		value = self:GetValue()
		if value == "" then value = nil end
		RefreshData(value)
	end
end

net.Receive("Hooker:ServerHooksCallback", function(len, ply)
	serverHooksCache = net.ReadTable() or {}
	clientHooksCache = hook.GetTable() or {}
	RefreshData()
end)

net.Receive("Hooker:OpenClientMenu", function() DrawFrame() end)

local function GetFunctionArgs(func)
	local info, params = debug.getinfo(func, "u"), {}
	for i = 1, info.nparams do
		params[i] = debug.getlocal(func, i)
	end
	if info.isvararg then
		params[#params + 1] = "..."
	end
	return table.concat(params, ", ")
end

-- hook.Add("Hooker:DataPopulated", "Hooker:Finished", function() CreateFrame() end)

