local path = require("path")
local filesys = require("fs")
local process = require("process")

local M = {}

local stats = filesys.statSync
local exists = filesys.existsSync

local pattern = '([^"="]+)'

process = process.globalProcess()

function M.set_value(key, value)
	if not key or not value then
		return false
	end
	process.env[key] = value
	return true
end

function M.get_value(key)
	return process.env[key] or nil
end

function M.load_env(route)
	if route then
		if not exists(route) then
			error('Unable to find path "' .. route .. '"')
		end
	else
		-- Path of current directory
		route = path.resolve()
	end

	-- Returns data on the file/dir
	local stat = stats(route)

	if stat and stat.type == "directory" then
		return M.load_env(path.join(route, ".env"))
	end

	local dotenv = io.open(route, "r")
	if not dotenv then
		return false
	end

	-- Parse content of file
	local parsed = {}

	for line in dotenv:lines() do
		local inner = {}

		for value in string.gmatch(line, pattern) do
			table.insert(inner, value)
		end

		table.insert(parsed, inner)
	end

	for _, p in ipairs(parsed) do
		M.set_value(unpack(p))
	end
	return io.close(dotenv)
end

return M
