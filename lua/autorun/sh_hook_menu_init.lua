HOOKMENU = HOOKMENU or {}

if SERVER then
	AddCSLuaFile("hook_menu/client/cl_menu.lua")

	include("hook_menu/server/sv_hook_menu.lua")

	MsgC(Color(255, 255, 0), "[HookMenu] Notice: HookMenu is a heavy tool. Opening the menu may lag your game and your server!")
end

if CLIENT then
	include("hook_menu/client/cl_menu.lua")
end