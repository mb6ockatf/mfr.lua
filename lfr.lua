#!/usr/bin/env lua
--- lua formatter
-- @module lfr

local function compare(first, second) return first.value < second.value end

local function check_argument(argument, accepted_type, error_message)
	if type(argument) ~= accepted_type then error(error_message) end
end

local function deepcopy(orig)
    local orig_type, copy = type(orig)
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else  -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

lfr = {_MAX_RECURSION = 5, _QUOTING_CHARACTER = '"',
_FG_COLORS = {black = "\27[30m", red = "\27[31m", green = "\27[32m",
orange = "\27[33m", blue = "\27[34m", purple = "\27[35m", cyan = "\27[36m",
light_gray = "\27[37m", default = "\27[39m", dark_grey = "\27[90m",
light_red = "\27[91m", light_green = "\27[92m", yellow = "\27[93m",
light_blue = "\27[94m", light_purple = "\27[95m", light_cyan = "\27[96m",
white = "\27[97m"},
_BG_COLORS = {black = "\27[40m", red = "\27[41m", green = "\27[42m",
yellow = "\27[43m", blue = "\27[44m", magenta = "\27[45m", cyan = "\27[46m",
white = "\27[47m", default = "\27[49m", light_black = "\27[100m",
light_red = "\27[101m", light_green = "\27[102m", light_yellow = "\27[103m",
light_blue = "\27[104m", light_magenta = "\27[105m", light_cyan = "\27[106m",
light_white = "\27[107m"},
_SPECIAL_STYLES = {bold = "\27[1m", nobold = "\27[22m",
underline = "\27[4m", nounderline = "\27[24m", negative = "\27[7m",
nonegative = "\27[27m"},
_cache = {}
}

--- send available foreground colors to stdout.
function lfr.describe_fg_colors()
	local result, default_style, temp = "", lfr._FG_COLORS.default, {}
	if not lfr._cache._FG_COLORS_STRING then
		local max_key_len, key_length = 0
		for key, value in pairs(lfr._FG_COLORS) do
			key_length = key:len()
			if key_length > max_key_len then
				max_key_len = key_length
			end
			value_table = {color_name = key, value = value}
			table.insert(temp, value_table)
		end
		table.sort(temp, compare)
		for _, color in pairs(temp) do
			local tab_length = max_key_len - color.color_name:len()
			result = result .. color.value .. color.color_name
			result = result .. string.rep(" ", tab_length)
			result = result .. " = " .. color.value:sub(2)
			result = result .. default_style .. "\n"
		end
		lfr._cache._FG_COLORS_STRING = result
	end
	io.write(lfr._cache._FG_COLORS_STRING)
end

--- send available background colors to stdout.
function lfr.describe_bg_colors()
	local result, default_style, temp = "", lfr._BG_COLORS.default, {}
	if not lfr._cache._BG_COLORS_STRING then
		local max_key_len, key_length = 0
		for key, value in pairs(lfr._BG_COLORS) do
			key_length = key:len()
			if key_length > max_key_len then
				max_key_len = key_length
			end
			value_table = {color_name = key, value = value}
			table.insert(temp, value_table)
		end
		table.sort(temp, compare)
		for _, color in pairs(temp) do
			local tab_length = max_key_len - color.color_name:len()
			result = result .. color.value .. color.color_name
			result = result .. string.rep(" ", tab_length)
			result = result .. " = " .. color.value:sub(2)
			result = result .. default_style .. "\n"
		end
		lfr._cache._BG_COLORS_STRING = result
	end
	io.write(lfr._cache._BG_COLORS_STRING)
end

--- send available special styles to stdout.
function lfr.describe_special_styles()
	local result, temp = "", {}
	if not lfr._cache._SPECIAL_STYLES_STRING then
		local max_key_len, key_length = 0
		for key, _ in pairs(lfr._SPECIAL_STYLES) do
			key_length = key:len()
			if key_length > max_key_len then max_key_len = key_length end
		end
		for key, element in pairs(lfr._SPECIAL_STYLES) do
			local tab_length = max_key_len - key:len()
			io.write(key.sub(1, 2))
			if key:sub(1, 2) == "no" then goto continue end
			result = result .. element .. key .. string.rep(" ", tab_length)
			result = result .. ": " .. element:sub(2)
			result = result .. lfr._SPECIAL_STYLES["no" .. key] .. "\n"
			::continue::
		end
		lfr._cache._SPECIAL_STYLES_STRING = result
	end
	io.write(lfr._cache._SPECIAL_STYLES_STRING)
end

--- make a good-looking string out of a table.
-- @raise error if ugly_table param is not a table.
-- @usage
-- useless_list = {1, 2, a = {"text", "text"}}
-- pretty_table = lfr.prettify_table(useless_list))
-- io.write(pretty_table)
-- @tparam table ugly_table
-- @treturn string pretty table ready to be sent to stdout
function lfr.prettify_table(ugly_table, _recursion_level)
	local error_message = "prettify_table accepts only table argument"
	check_argument(ugly_table, "table", error_message)
	local quote = lfr._QUOTING_CHARACTER
	if type(_recursion_level) == "nil" then
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
			key = quote .. key .. quote
		end
		nice_message = nice_message .. tabulation .. key .. ": " .. value
		nice_message = nice_message .. "\n"
	end
	return nice_message .. string.rep("\t", _recursion_level - 1) .. "}\n"
end

--- make a good-looking string out of anything.
-- @usage
-- perfect_table = {1, 2, a = {"text1", "text2"}}
-- lfr.pprint(perfect_table)
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
-- @see lfr.set_max_recursion
-- @within settings
function lfr.set_max_recursion(value)
	local error_message = "set_max_recursion accepts signed number argument"
	check_argument(value, "number", error_message)
	if value < 0 then error(error_message) end
	lfr._MAX_RECURSION = value
end

--- get maximal recursion level.
-- @treturn number maximal recursion level
-- @see lfr.set_max_recursion
-- @within settings
function lfr.get_max_recursion()
	return lfr._MAX_RECURSION
end

--- set string quoting character.
-- @raise error if character param is not string.
-- @tparam string character new quote character
-- @see lfr.get_string_quoting
-- @within settings
function lfr.set_string_quoting(character)
	local error_message = "set_string_quotes accepts only string argument"
	check_argument(character, "string", error_message)
	lfr._QUOTING_CHARACTER = character
end

--- get string quoting character.
-- @treturn string quoting character
-- @see lfr.set_string_quoting
-- @within settings
function lfr.get_string_quoting()
	return lfr._QUOTING_CHARACTER
end
return lfr
