util.AddNetworkString("Hooker:OpenClientMenu")
util.AddNetworkString("Hooker:RefreshHooks")
util.AddNetworkString("Hooker:ServerHooksCallback")

concommand.Add("hooker", function(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	HOOKER:OpenMenu(ply)
end)

function HOOKER:OpenMenu(ply)
	net.Start("Hooker:OpenClientMenu")
	net.Send(ply)
end

net.Receive("Hooker:RefreshHooks", function(len, ply)
	local hookList = hook.GetTable()

	--[[
		This bad boy code allow to transform all of the hook.GeTable() function to a strings
		in order to send the table to the client.
		Sending directly hook.GeTable() (a function that returns a table) via net.WriteTable()
		was throwing an error, even if type(hook.GeTable()) is a table... <3 lua.
		Btw, this is super heavy to send but... you know
	]]
	local hooks = {}
	for hookName, hookChild in SortedPairs(hookList) do
		local childs = {}
		for childName, childFunction in pairs(hookChild) do
			childName, childFunction = tostring(childName), tostring(childFunction)
			-- Structure: hooks[hookName] = {[childName] = childFunction}
			childs[childName] = childFunction
		end
		hooks[hookName] = childs
	end

	net.Start("Hooker:ServerHooksCallback")
	net.WriteTable(hooks)
	net.Send(ply)
end)
