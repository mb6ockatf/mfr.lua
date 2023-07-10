#!/usr/bin/env lua
--- lua formatter
-- @module lfr

--- check if element belongs to array
-- @param element element to search for
-- @tparam table sequence array to search in
-- @treturn boolean true if element exists in sequence, otherwise false
local function belongs(element, sequence)
	for i=1, #sequence, 1 do if element == sequence[i] then return true end end
	return false
end

--- compare tables when sorting.
-- both arguments must contain `value` field.
-- @tparam table first table to be compared with second table
-- @tparam table second table to be compared with first table
-- @treturn boolean true if first.value is less than second.value, else false
local function compare(first, second) return first.value < second.value end

--- recursively copy table.
-- note that this is a recursive function.
-- always check the data you process for safety! if `orig` is a table and is 
-- more nested than lfr._MAX_RECURSION, then `orig` will be copied up to
-- lfr._MAX_RECURSION nested level without warning.
-- @tparam any orig original value. if it is not a table-like object, it is 
-- just returned
-- @treturn any copy of orig (same type, as `orig` parameter)
local function deepcopy(orig, _recursion_level)
	if type(_recursion_level) == "nil" then _recursion_level = 0
	elseif _recursion_level > lfr._MAX_RECURSION then return orig end
	_recursion_level = _recursion_level + 1
	local orig_type, copy = type(orig)
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value, _recursion_level)
		end
		setmetatable(copy, deepcopy(getmetatable(orig), _recursion_level))
	else  -- number, string, boolean, etc
		copy = orig
	end
	return copy
end
	
--- split string by `separator` and return array.
-- @tparam string str text to be splitted by `separator`
-- @tparam string separator string to split `str` with
local function split(str, separator)
	if separator == nil then separator = " "
	elseif type(separator) ~= "string" then
		error("separator argument must be string")
	end
	local result, buffer, character = {}, ""
	for i = 1, #str, 1 do
		character = str:sub(i, i)
		if character ~= separator then buffer = buffer .. character
		else
			table.insert(result, buffer)
			buffer = ""
		end
	end
	table.insert(result, buffer)
	return result
end

--- execute system shell command.
-- @tparam string command command to be sent for execution
-- @treturn any shell answer. nil if command returned non-zero exit code 
-- (failed)
local function execute_system_command(command)
	local handle = io.popen(command)
	local output = handle:read("*a")
	handle:close()
	return output
end

lfr = {_MAX_RECURSION = 5, _cache = {},
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
}

--- create frame with message in terminal.
-- @tparam string message text to be displayed
-- @tparam number width width of the frame
-- @tparam string pattern pattern to be used to create frame
-- @treturn string framed message
function lfr.create_frame(message, width, pattern)
	local list = {"table", "nil"}
	assert(type(message) == "string", "message argument is string")
	assert(belongs(type(width), {"number", "nil"}),
	"size argument is table or nil")
	assert(belongs(type(pattern), {"string", "nil"}),
	"pattern argument is string or nil")
	assert(belongs(type(position), list), "position argument is table or nil")
	local length, current_length, buffer, top_border = message:len(), 0, ""
	if width == nil then width = 80 end
	if pattern == nil then pattern = "*" end
	top_border = string.rep(pattern, width) .. "\n"
	result = top_border .. pattern .. " "
	if length < width - 4 then
		result = result .. message .. string.rep(" ", width - length - 3)
		result = result .. pattern .. "\n" .. top_border
		return result
	end
	message = split(message)
	for index, word in ipairs(message) do
		current_length = current_length + word:len() + 1
		buffer = buffer .. word .. " "
		if index + 1 > #message then
			;
		elseif current_length + message[index + 1]:len() > width - 4 then
			buffer = buffer:sub(1, -2)
			result = result .. buffer
			result = result .. string.rep(" ", width - buffer:len() - 3)
			result = result .. pattern .. "\n" .. pattern .. " "
			buffer, current_length = "", 0
		end
	end
	result = result .. buffer:sub(1, -2) .. string.rep(" ", width - buffer:len() - 2)
	return result .. pattern .. "\n".. top_border
end

--- @section showing

--- send available foreground colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function lfr.describe_fg_colors(is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support colors")
	end
	local result, default_style, temp = "", lfr._FG_COLORS.default, {}
	if lfr._cache._FG_COLORS_STRING then
		io.write(lfr._cache._FG_COLORS_STRING)
		return
	end
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
	io.write(lfr._cache._FG_COLORS_STRING)
end

--- send available background colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function lfr.describe_bg_colors(is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support colors")
	end
	if lfr._cache._BG_COLORS_STRING then
		io.write(lfr._cache._BG_COLORS_STRING)
		return
	end
	local result, default_style, temp = "", lfr._BG_COLORS.default, {}
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
	io.write(lfr._cache._BG_COLORS_STRING)
end

--- send available special styles to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function lfr.describe_special_styles(is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	if lfr._cache._SPECIAL_STYLES_STRING then
		io.write(lfr._cache._SPECIAL_STYLES_STRING)
		return
	end
	local result, temp, max_key_len, key_length = "", {}, 0
	for key, _ in pairs(lfr._SPECIAL_STYLES) do
		key_length = key:len()
		if key_length > max_key_len then max_key_len = key_length end
	end
	for key, element in pairs(lfr._SPECIAL_STYLES) do
		local tab_length = max_key_len - key:len()
		io.write(key.sub(1, 2))
		if key:sub(1, 2) ~= "no" then
			result = result .. element .. key .. string.rep(" ", tab_length)
			result = result .. ": " .. element:sub(2)
			result = result .. lfr._SPECIAL_STYLES["no" .. key] .. "\n"
		end
	end
	lfr._cache._SPECIAL_STYLES_STRING = result
	io.write(lfr._cache._SPECIAL_STYLES_STRING)
end

--- clear terminal screen.
function lfr.clear_screen()
	io.write("\27[2J\27[1;1H")
	io.flush()
end

--- check if terminal supports colors.
-- @treturn number number of supported colors
-- @treturn boolean false if colors aren't supported
function lfr.is_supporting_colors()
	if lfr._cache._IS_SUPPORTING_COLORS then
		return lfr._cache._IS_SUPPORTING_COLORS
	end
	if package.config.sub(1, 1) == "\\" then return 16 end
	local colors_number = tonumber(execute_system_command("tput colors")) 
	colors_number = colors_number or 0
	local no_colors = os.getenv("NO_COLOR")
	if colors_number > 0 or no_colors ~= "true" then
		lfr._cache._IS_SUPPORTING_COLORS = colors_number
	else lfr._cache._IS_SUPPORTING_COLORS = false end
	return lfr._cache._IS_SUPPORTING_COLORS
end

--- apply background color to string.
-- @tparam string message string apply background color to
-- @tparam string color background color to be applied to message
-- @tparam boolean is_closed whether style will be disabled with end of message
-- @tparam boolean is_forced whether style will be applied evem if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string colorful message
-- @see lfr.describe_bg_colors
function lfr.set_bg(message, color, is_closed, is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	local result = lfr._BG_COLORS[color] .. message
	if is_closed == nil then is_closed = true end
	if is_closed then result = result .. lfr._BG_COLORS.default end
	return  result
end

--- apply foreground color to string.
-- @tparam string message string apply color to
-- @tparam string color color to be applied to message
-- @tparam boolean is_forced whether style will be applied even if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string colorful message
-- @see lfr.describe_fg_colors
function lfr.set_fg(message, color, is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	return lfr._FG_COLORS[color] .. message .. lfr._FG_COLORS.default
end

--- apply special style to string.
-- @tparam string message string apply style to
-- @tparam string style style to be applied to message
-- @tparam boolean is_forced whether style will be applied even if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string styled message
-- @see lfr.describe_special_styles
function lfr.set_special_style(message, style, is_forced)
	if not is_forced and not lfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	local closer
	if style == "negative" then
		closer = lfr._SPECIAL_STYLES["nonegative"]
	elseif style == "bold" then
		closer = lfr._SPECIAL_STYLES["nobold"]
	elseif styly == "underline" then
		closer = lfr._SPECIAL_STYLES["nounderline"]
	end
	return lfr._SPECIAL_STYLES[style] .. message .. closer
end

--- make a good-looking string out of a table.
-- @usage
-- useless_list = {1, 2, a = {"text", "text"}}
-- pretty_table = lfr.prettify_table(useless_list))
-- io.write(pretty_table)
-- @tparam table ugly_table
-- @treturn string pretty table ready to be sent to stdout
function lfr.prettify_table(ugly_table, _recursion_level)
	if type(_recursion_level) == "nil" then
		_recursion_level = 0
	elseif _recursion_level > lfr._MAX_RECURSION then
		_recursion_level = _recursion_level - 1
	end
	local nice_msg = string.rep("\t", _recursion_level - 1) .. "{\n"
	local tabulation = string.rep("\t", _recursion_level + 1)
	local key_type, value_type
	_recursion_level = _recursion_level + 1
	for key, value in pairs(ugly_table) do
		key_type, value_type = type(key), type(value)
		if key_type == "table" then
			key = lfr.prettify_table(key, _recursion_level)
		elseif key_type == "string" then
			key = string.format('%q', key)
		else
			key = tostring(key)
		end
		if value_type == "table" then
			value = lfr.prettify_table(value, _recursion_level)
		elseif value_type == "string" then
			value = string.format('%q', value)
		else
			value = tostring(value)
		end
		nice_msg = nice_msg .. tabulation .. key .. " = " .. value .. ",\n"
	end
	local result = nice_msg .. string.rep("\t", _recursion_level - 1) .. "}"
	return result
end

--- make a good-looking string out of anything.
-- @usage
-- perfect_table = {1, 2, a = {"text1", "text2"}}
-- lfr.pprint(perfect_table)
-- @param object anything to be pretty-printed
function lfr.pprint(object)
	local object_type, result = type(object)
	if object_type == "table" then result = lfr.prettify_table(object, 0)
	else result = tostring(object) end
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
	assert(type(value) == "number", error_message)
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

return lfr