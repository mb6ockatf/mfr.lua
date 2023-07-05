#!/usr/bin/env lua
-- @module lfr
local lfr = {}
local MAX_RECURSION = 5


--- prettify_table
-- make a good-looking string out of a table
-- raises an error if ugly_table param is not a table
-- @usage
local usage = [[
my_table = {1, 2, a = {"text", "text"}}
nice_output = lfr.prettify_table(my_table)
io.write(nice_output)
]]
-- @tparam ugly_table table
-- @treturn string your pretty table ready to be sent to stdout
function lfr.prettify_table(ugly_table, _recursion_level)
	local param_type = type(ugly_table)
	if param_type ~= "table" then
		error("prettify_table accepts only table, not " .. param_type)
	elseif type(_recursion_level) == "nil" then
		_recursion_level = 0
	elseif _recursion_level > MAX_RECURSION then
		_recursion_level = _recursion_level - 1
	end
	local nice_message = string.rep("\t", _recursion_level) .. "{\n"
	local tabulation = string.rep("\t", _recursion_level + 1)
	_recursion_level = _recursion_level + 1
	for key, value in pairs(ugly_table) do
		if type(value) == "table" then
			value = lfr.prettify_table(value, _recursion_level)
		end
		if type(key) ~= "number" then
			key = '"' .. key .. '"'
		end
		nice_message = nice_message .. tabulation .. key .. ": " .. value
		nice_message = nice_message .. "\n"
	end
	return nice_message .. string.rep("\t", _recursion_level - 1) .. "}\n"
end

function lfr.pprint(object)
	local object_type, result = type(object)
	if object_type == "table" then
		result = lfr.prettify_table(object, 0)
	else
		result = tostring(object)
	end
	if IS_UNDER_TESTING ~= true then io.write(result) end
end

return lfr