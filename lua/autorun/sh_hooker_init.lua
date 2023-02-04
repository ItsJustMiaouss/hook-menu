HOOKER = HOOKER or {}

if SERVER then
	AddCSLuaFile("hooker/client/cl_menu.lua")

	include("hooker/server/sv_hooker.lua")

	MsgC(Color(255, 255, 0), "[HOOKER] Notice: Hooker is a heavy tool. Opening a menu may lag your game or your server!")
end

if CLIENT then
	include("hooker/client/cl_menu.lua")
end