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
	if not ply:IsSuperAdmin() then return end
	local hookList = hook.GetTable()

	--[[
		This bad boy code allow to transform all of the hook.GeTable() function to strings
		in order to send the table to the client.
		Sending directly hook.GeTable() (a function that returns a table) via net.WriteTable()
		was throwing an error, even if type(hook.GeTable()) is a table... <3 lua.
		Btw, this is super heavy to send but... you know
	]]
	local hooks = {}
	for hookName, hookChild in SortedPairs(hookList) do
		local childs = {}
		for childName, childFunction in pairs(hookChild) do
			-- Get the hook function data (e.g. position in file...)
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

	net.Start("Hooker:ServerHooksCallback")
	-- The table is soo heavy that I need to compress data...
	local jsonHooks = util.TableToJSON(hooks)
	local compressedHooks = util.Compress(jsonHooks)

	net.WriteUInt(#compressedHooks, 16)
	net.WriteData(compressedHooks, #compressedHooks)
	net.Send(ply)
end)
