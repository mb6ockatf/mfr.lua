#!/usr/bin/env lua
--- lua formatter
-- @module mfr

--- check if element belongs to array
-- @param element element to search for
-- @tparam table sequence array to search in
-- @treturn boolean true if element exists in sequence, otherwise false
local function belongs(element, sequence)
	for i=1, #sequence, 1 do if element == sequence[i] then return true end end
	return false
end


--- cut string into slices of certain length.
-- @tparam string str string to be sliced
-- @tparam number length slices' length
-- @treturn table list of slices
local function cut_string(str, length)
	local result, counter = {"",}, 0
	for character_index = 1, #str do
		if counter < length then
			counter = counter + 1
			result[#result] = result[#result] .. str[character_index]
		else
			counter = 0
			table.insert(result, str[character_index])
		end
	end
	return result
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
-- more nested than mfr._MAX_RECURSION, then `orig` will be copied up to
-- mfr._MAX_RECURSION nested level without warning.
-- @tparam any orig original value. if it is not a table-like object, it is 
-- just returned
-- @treturn any copy of orig (same type, as `orig` parameter)
local function deepcopy(orig, _recursion_level)
	if type(_recursion_level) == "nil" then _recursion_level = 0
	elseif _recursion_level > mfr._MAX_RECURSION then return orig end
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
	if buffer:len() > 0 then table.insert(result, buffer) end
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

mfr = {
	_MAX_RECURSION = 5, _TAB_REPRESENTATION = string.rep(" ", 4), _cache = {},
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
	light_blue = "\27[104m", light_magenta = "\27[105m",
	light_cyan = "\27[106m", light_white = "\27[107m"},
	_SPECIAL_STYLES = {bold = "\27[1m", nobold = "\27[22m",
	underline = "\27[4m", nounderline = "\27[24m", negative = "\27[7m",
	nonegative = "\27[27m"},
}

--- create frame with message in terminal.
-- note that all tabs will be converted to character sequence defined by
-- `set_tab_representation` - 4 spaces is a default value.
-- @tparam string message text to be displayed
-- @tparam number width width of the frame
-- @tparam string pattern pattern to be used to create frame
-- @treturn string framed message
-- @see mfr.set_tab_representation
function mfr.create_frame(message, width, pattern)
	local list = {"table", "nil"}
	if type(message) == "table" and not width and not pattern then
		pattern, width = message.pattern, message.width
		message = message.message
	end
	assert(type(message) == "string", "message argument is string")
	assert(belongs(type(width), {"number", "nil"}), "width is table or nil")
	assert(belongs(type(pattern), {"string", "nil"}),
	"pattern is string or nil")
	width, pattern = width or 80, pattern or "*"
	if pattern:len() == 0 then pattern = "*" end
	pattern = pattern:sub(1)
	if width < 5 then error("width is larger than 4 characters") end
	local top_border, result = string.rep(pattern, width) .. "\n", {}
	local temp, long_line, word_length, str_line
	local current_line_length = 0
	local message_length, str_result = message:len(), ""
	width = width - 4
	message = split(message:gsub("\t", mfr._TAB_REPRESENTATION), "\n")
	for _, stuff_between_newlines in ipairs(message) do
		temp = {}
		long_line = split(stuff_between_newlines)
		for __, word in ipairs(long_line) do
			word_length = word:len()
			if current_line_length + word_length < width then
				table.insert(temp, word)
				current_line_length = current_line_length + word_length + 1
			else
				table.insert(result, temp)
				if word_length < width then
					temp, current_line_length = {word}, word_length + 1
				else
					for _, line in ipairs(cut_string(word, width)) do
						table.insert(result, {line,})
					end
					current_line_length = 0
				end
			end
		end
		if #temp > 0 then table.insert(result, temp); temp = {} end
	end
	for _, line in ipairs(result) do
		str_line = table.concat(line, " ")
		str_result = str_result .. pattern .. " " .. str_line
		str_result = str_result .. string.rep(" ", width - str_line:len() + 1)
		str_result = str_result .. pattern .. "\n"
	end
	return top_border .. str_result .. top_border
end

--- @section showing

--- send available foreground colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_fg_colors(is_forced)
	if is_forced == nil then is_forced = false end
	if (not is_forced) and (not mfr.is_supporting_colors()) then
		error("terminal does not support colors")
	end
	local result, default_style, temp = "", mfr._FG_COLORS.default, {}
	if mfr._cache._FG_COLORS_STRING then
		if IS_UNDER_TESTING ~= true then
			io.write(mfr._cache._FG_COLORS_STRING)
		end
		return
	end
	local max_key_len, key_length = 0
	for key, value in pairs(mfr._FG_COLORS) do
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
	mfr._cache._FG_COLORS_STRING = result
	if IS_UNDER_TESTING ~= true then
		io.write(mfr._cache._FG_COLORS_STRING)
	end
end

--- send available background colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_bg_colors(is_forced)
	if not is_forced and not mfr.is_supporting_colors() then
		error("terminal does not support colors")
	end
	if mfr._cache._BG_COLORS_STRING then
		if IS_UNDER_TESTING ~= true then
			io.write(mfr._cache._BG_COLORS_STRING)
		end
		return
	end
	local result, default_style, temp = "", mfr._BG_COLORS.default, {}
	local max_key_len, key_length = 0
	for key, value in pairs(mfr._BG_COLORS) do
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
	mfr._cache._BG_COLORS_STRING = result
	if IS_UNDER_TESTING ~= true then
		io.write(mfr._cache._BG_COLORS_STRING)
	end
end

--- send available special styles to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_special_styles(is_forced)
	if not is_forced and not mfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	if mfr._cache._SPECIAL_STYLES_STRING then
		if IS_UNDER_TESTING ~= true then
			io.write(mfr._cache._SPECIAL_STYLES_STRING)
		end
		return
	end
	local result, temp, max_key_len, key_length = "", {}, 0
	for key, _ in pairs(mfr._SPECIAL_STYLES) do
		key_length = key:len()
		if key_length > max_key_len then max_key_len = key_length end
	end
	for key, element in pairs(mfr._SPECIAL_STYLES) do
		local tab_length = max_key_len - key:len()
		io.write(key.sub(1, 2))
		if key:sub(1, 2) ~= "no" then
			result = result .. element .. key .. string.rep(" ", tab_length)
			result = result .. ": " .. element:sub(2)
			result = result .. mfr._SPECIAL_STYLES["no" .. key] .. "\n"
		end
	end
	mfr._cache._SPECIAL_STYLES_STRING = result
	if IS_UNDER_TESTING ~= true then
		io.write(mfr._cache._SPECIAL_STYLES_STRING)
	end
end

--- clear terminal screen.
function mfr.clear_screen()
	io.write("\27[3J\27[H\27[2J")
	io.flush()
end

--- check if terminal supports colors.
-- @treturn number number of supported colors
-- @treturn boolean false if colors aren't supported
function mfr.is_supporting_colors()
	if mfr._cache._IS_SUPPORTING_COLORS then
		return mfr._cache._IS_SUPPORTING_COLORS
	end
	if package.config.sub(1, 1) == "\\" then return 16 end
	local colors_number = tonumber(execute_system_command("tput colors")) 
	colors_number = colors_number or 0
	local no_colors = os.getenv("NO_COLOR")
	if colors_number > 0 and no_colors ~= "true" then
		mfr._cache._IS_SUPPORTING_COLORS = colors_number
	else mfr._cache._IS_SUPPORTING_COLORS = false end
	return mfr._cache._IS_SUPPORTING_COLORS
end

--- apply background color to string.
-- @tparam string message string apply background color to
-- @tparam string color background color to be applied to message
-- @tparam boolean is_closed whether style will be disabled with end of message
-- @tparam boolean is_forced whether style will be applied evem if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string colorful message
-- @see mfr.describe_bg_colors
function mfr.set_bg(message, color, is_closed, is_forced)
	if not is_forced and not mfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	local result = mfr._BG_COLORS[color] .. message
	if is_closed == nil then is_closed = true end
	if is_closed then result = result .. mfr._BG_COLORS.default end
	return  result
end

--- apply foreground color to string.
-- @tparam string message string apply color to
-- @tparam string color color to be applied to message
-- @tparam boolean is_forced whether style will be applied even if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string colorful message
-- @see mfr.describe_fg_colors
function mfr.set_fg(message, color, is_forced)
	if not is_forced and not mfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	return mfr._FG_COLORS[color] .. message .. mfr._FG_COLORS.default
end

--- apply special style to string.
-- @tparam string message string apply style to
-- @tparam string style style to be applied to message
-- @tparam boolean is_forced whether style will be applied even if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string styled message
-- @see mfr.describe_special_styles
function mfr.set_special_style(message, style, is_forced)
	if not is_forced and not mfr.is_supporting_colors() then
		error("terminal does not support special styles")
	end
	local closer
	if style == "negative" then
		closer = mfr._SPECIAL_STYLES["nonegative"]
	elseif style == "bold" then
		closer = mfr._SPECIAL_STYLES["nobold"]
	elseif styly == "underline" then
		closer = mfr._SPECIAL_STYLES["nounderline"]
	end
	return mfr._SPECIAL_STYLES[style] .. message .. closer
end

--- make a good-looking string out of a table.
-- @usage
-- useless_list = {1, 2, a = {"text", "text"}}
-- pretty_table = mfr.prettify_table(useless_list))
-- io.write(pretty_table)
-- @tparam table ugly_table
-- @treturn string pretty table ready to be sent to stdout
function mfr.prettify_table(ugly_table, _recursion_level)
	if type(_recursion_level) == "nil" then
		_recursion_level = 0
	elseif _recursion_level > mfr._MAX_RECURSION then
		_recursion_level = _recursion_level - 1
	end
	local nice_msg = string.rep("\t", _recursion_level - 1) .. "{\n"
	local tabulation = string.rep("\t", _recursion_level + 1)
	local key_type, value_type
	_recursion_level = _recursion_level + 1
	for key, value in pairs(ugly_table) do
		key_type, value_type = type(key), type(value)
		if key_type == "table" then
			key = mfr.prettify_table(key, _recursion_level)
		elseif key_type == "string" then
			key = string.format('%q', key)
		else
			key = tostring(key)
		end
		if value_type == "table" then
			value = mfr.prettify_table(value, _recursion_level)
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
-- mfr.pprint(perfect_table)
-- @param object anything to be pretty-printed
function mfr.pprint(object)
	local object_type, result = type(object)
	if object_type == "table" then result = mfr.prettify_table(object, 0)
	else result = tostring(object) end
	if IS_UNDER_TESTING ~= true then io.write(result) end
end

--- @section settings

--- set maximal recursion level.
-- for instance, recursion level 7 means that  recursive function cannot call
-- itself more than 7 times.
-- @raise error if value param is not a signed number.
-- @tparam number value new recursion level
-- @see mfr.set_max_recursion
-- @within settings
function mfr.set_max_recursion(value)
	local error_message = "set_max_recursion accepts signed number argument"
	assert(type(value) == "number", error_message)
	if value < 0 then error(error_message) end
	mfr._MAX_RECURSION = value
end

--- get maximal recursion level.
-- @treturn number maximal recursion level
-- @see mfr.set_max_recursion
-- @within settings
function mfr.get_max_recursion()
	return mfr._MAX_RECURSION
end

--- set tab representation.
-- for instance, tab representation "    " (default value) means that tab 
-- symbol will be substituted for 4 spaces in functions that need tab to have 
-- stable length.
-- @raise error if value param is not a string.
-- @tparam string value new tab representation
-- @see mfr.get_tab_representation
-- @within settings
function mfr.set_tab_representation(value)
	local error_message = "set_tab_representation accepts only string argument"
	assert(type(value) == "string", error_message)
	mfr._TAB_REPRESENTATION = value
end

--- get tab representation.
-- @treturn string current tab representation
-- @see mfr.set_tab_representation
-- @within settings
function mfr.get_tab_representation()
	return mfr._TAB_REPRESENTATION
end
return mfr