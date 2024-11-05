util.AddNetworkString("HookMenu:OpenClientMenu")
util.AddNetworkString("HookMenu:RefreshHooks")
util.AddNetworkString("HookMenu:ServerHooksCallback")

concommand.Add("hook_menu", function(ply, cmd, args)
	if not ply:IsSuperAdmin() then return end
	HOOKMENU:OpenMenu(ply)
end)

function HOOKMENU:OpenMenu(ply)
	net.Start("HookMenu:OpenClientMenu")
	net.Send(ply)
end

net.Receive("HookMenu:RefreshHooks", function(len, ply)
	if not ply:IsSuperAdmin() then return end
	local hookList = hook.GetTable()

	--[[
		Transform the hook.GeTable() result to strings in order to send the table to the client.
		The table itself was too heavy to be sent directly.
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

	net.Start("HookMenu:ServerHooksCallback")
	-- Compress the data and send it to the client.
	local jsonHooks = util.TableToJSON(hooks)
	local compressedHooks = util.Compress(jsonHooks)

	net.WriteUInt(#compressedHooks, 16)
	net.WriteData(compressedHooks, #compressedHooks)
	net.Send(ply)
end)
