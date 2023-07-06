#!/usr/bin/env lua
--- lua formatter
-- @module lfr
local lfr = {}
lfr._MAX_RECURSION = 5


--- make a good-looking string out of a table.
-- @raise error if ugly_table param is not a table.
-- @usage io.write(lfr.prettify_table({1, 2, a = {"text", "text"}}))
-- @tparam table ugly_table
-- @treturn string pretty table ready to be sent to stdout
function lfr.prettify_table(ugly_table, _recursion_level)
	local param_type = type(ugly_table)
	if param_type ~= "table" then
		error("prettify_table accepts only table argument, not " .. param_type)
	elseif type(_recursion_level) == "nil" then
		_recursion_level = 0
	elseif _recursion_level > lfr._MAX_RECURSION then
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

--- make a good-looking string out of anything.
-- @usage lfr.pprint({1, 2, a = {"text", "text"}}))
-- @param object anything to be pretty-printed
function lfr.pprint(object)
	local object_type, result = type(object)
	if object_type == "table" then
		result = lfr.prettify_table(object, 0)
	else
		result = tostring(object)
	end
	if IS_UNDER_TESTING ~= true then io.write(result) end
end

--- @section settings

--- set maximal recursion level.
-- for instance, recursion level 7 means that  recursive function cannot call
-- itself more than 7 times.
-- @raise error if value param is not a signed number.
-- @tparam number value new recursion level
-- @usage lfr.set_max_recursion(7)
-- @see pprint
-- @within settings
function lfr.set_max_recursion(value)
	local param_type = type(value)
	local error_message = "set_max_recursion accepts only signed number argument"
	if param_type ~= "number" then
		error(error_message .. ", not " .. param_type)
	elseif param_type < 0 then
		error(error_message)
	end
	lfr._MAX_RECURSION = value
end

--- get maximal recursion level.
-- @treturn number maximal recursion level
-- @see lfr.set_max_recursion
-- @within settings
function lfr.get_max_recursion()
	return lfr._MAX_RECURSION
end

return lfr