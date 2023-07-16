#!/usr/bin/env lua
--- lua formatter
-- @module mfr

--- compare tables when sorting.
-- both arguments must contain `value` field.
-- @tparam table first table to be compared with second table
-- @tparam table second table to be compared with first table
-- @treturn boolean true if first.value is less than second.value, else false
local function compare(first, second) return first.value < second.value end

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
	nonegative = "\27[27m"}
}

--- cut string into slices of certain length.
-- @tparam string str string to be sliced
-- @tparam number length slices' length
-- @raise
-- if str is not a string
-- if length is not a number
-- @treturn table list of slices
function mfr.cut_string(str, length)
	assert(type(str) == "string", "str argument is string")
	assert(type(length) == "number", "length argument is number")
	local result, counter = {""}, 0
	for index = 1, #str do
		if counter < length then
			counter = counter + 1
			result[#result] = result[#result] .. str:sub(index, index)
		else counter = 1; table.insert(result, str:sub(index, index)) end
	end
	return result
end

--- recursively copy table.
-- note that this is a recursive function.
-- always check the data you process for safety! if `orig` is a table and is 
-- more nested than mfr._MAX_RECURSION, then `orig` will be copied up to
-- mfr._MAX_RECURSION nested level without warning.
-- @tparam any orig original value. if it is not a table-like object, it is 
-- just returned
-- @treturn any copy of orig (same type, as `orig` parameter)
function mfr.deepcopy(orig, _recursion_level)
	if type(_recursion_level) == "nil" then _recursion_level = 0
	elseif _recursion_level > mfr._MAX_RECURSION then return orig end
	_recursion_level = _recursion_level + 1
	local new_key, copy
	local orig_type = type(orig)
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			new_key = mfr.deepcopy(orig_key)
			copy[new_key] = mfr.deepcopy(orig_value, _recursion_level)
		end
		setmetatable(copy, mfr.deepcopy(getmetatable(orig), _recursion_level))
	else  -- number, string, boolean, etc
		copy = orig
	end
	return copy
end


--- check if element belongs to array.
-- @param element element to search for
-- @tparam table sequence array to search in
-- @treturn boolean true if element exists in sequence, otherwise false
-- @raise if sequence is not a table
function mfr.belongs(element, sequence)
	assert(type(sequence) == "table", "sequence is table")
	for i = 1, #sequence do if element == sequence[i] then return true end end
	return false
end

--- split string by `separator` and return array.
-- @tparam string str text to be splitted by `separator`
-- @tparam string separator string to split `str` with
-- @treturn table array of splitted strings.
-- @raise if str is not a string or separator is not a string and not nil.
function mfr.split(str, separator)
	assert(type(str) == "string", "str argument is string")
	separator = separator or " "
	assert(type(separator) == "string", "separator argument must be string")
	local result, buffer, inside_separator, sep_len = {}, "", 0, separator:len()
	for i = 1, #str do
		if inside_separator == 0 then
			if str:sub(i, i + sep_len - 1) ~= separator then
				buffer = buffer .. str:sub(i, i)
			else
				table.insert(result, buffer)
				inside_separator, buffer = sep_len - 1, ""
			end
		else inside_separator = inside_separator - 1 end
	end
	if buffer ~= "" then table.insert(result, buffer) end
	return result
end

--- @section system

--- execute system shell command.
-- @tparam string command command to be sent for execution
-- @raise if command is not a string
-- @treturn any shell answer. nil if command returned non-zero exit code
-- (failed)
-- @within system
function mfr.execute_system_command(command)
	assert(type(command) == "string", "command argument is string")
	local handle = io.popen(command)
	if handle then
		local output = handle:read("*a"); handle:close() return output; end
	return nil
end

--- check if terminal supports colors.
-- @treturn number number of supported colors
-- @treturn boolean false if colors aren't supported
-- @within system
function mfr.is_supporting_colors()
	if mfr._cache._IS_SUPPORTING_COLORS then
		return mfr._cache._IS_SUPPORTING_COLORS end
	if package.config:sub(1, 1) == "\\" then return 16 end
	local colors_number = tonumber(mfr.execute_system_command("tput colors"))
	colors_number = colors_number or 0
	if colors_number > 0 and os.getenv("NO_COLOR") ~= "true" then
		mfr._cache._IS_SUPPORTING_COLORS = colors_number
	else mfr._cache._IS_SUPPORTING_COLORS = false end
	return mfr._cache._IS_SUPPORTING_COLORS
end

--- @section color setters

--- apply background color to string.
-- @tparam string message string apply background color to (or table, if 
-- passing all arguments as 1 table). see usage for more
-- @tparam string color background color to be applied to message
-- @tparam boolean is_closed whether style will be disabled with end of message
-- @tparam boolean is_forced whether style will be applied evem if colors are 
-- not supported
-- @raise if colors are not supported and is_forced is not true
-- @treturn string colorful message
-- @usage
-- mfr.apply_bg_color("hello", "red")
-- mfr.apply_bg_color{message = "message", color = "red", is_closed = true, 
-- is_forced = false}
-- @see mfr.describe_bg_colors
-- @within color setters
function mfr.set_bg(message, color, is_closed, is_forced)
	if type(message) == "table" and not color then
		color, is_closed = message.color, message.is_closed
		is_forced  = message.is_forced
		message = message.message
	end
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
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
-- @within color setters
function mfr.set_fg(message, color, is_forced)
	if type(message) == "table" and not color then
		color, is_forced = message.color, message.is_forced
		message = message.message
	end
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
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
-- @within color setters
function mfr.set_special_style(message, style, is_forced)
	if type(message) == "table" and not style then
		style, is_forced = message.style, message.is_forced
		message = message.message
	end
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
	local closer
	if style == "negative" then closer = mfr._SPECIAL_STYLES["nonegative"]
	elseif style == "bold" then closer = mfr._SPECIAL_STYLES["nobold"]
	elseif style == "underline" then closer = mfr._SPECIAL_STYLES["nounderline"]
	end
	return mfr._SPECIAL_STYLES[style] .. message .. closer
end

--- @section prettifyers

--- clear terminal screen.
-- please, use with caution.
-- @within prettifyers
function mfr.clear_screen() io.write("\27[3J\27[H\27[2J"); io.flush(); end

--- make a good-looking string out of a table.
-- @usage
-- useless_list = {1, 2, a = {"text", "text"}}
-- pretty_table = mfr.prettify_table(useless_list))
-- io.write(pretty_table)
-- @tparam table ugly_table
-- @raise error if ugly_table is not a table.
-- @treturn string pretty table ready to be sent to stdout
-- @within prettifyers
function mfr.prettify_table(ugly_table, _recursion_level)
	assert(type(ugly_table) == "table", "ugly_table is table")
	_recursion_level = _recursion_level or 0
	if _recursion_level > mfr._MAX_RECURSION then
		_recursion_level = _recursion_level - 1 end
	local nice_msg = string.rep("\t", _recursion_level - 1) .. "{\n"
	local tabulation = string.rep("\t", _recursion_level + 1)
	local key_type, value_type
	_recursion_level = _recursion_level + 1
	for key, value in pairs(ugly_table) do
		key_type, value_type = type(key), type(value)
		if key_type == "table" then
			key = mfr.prettify_table(key, _recursion_level)
		elseif key_type == "string" then key = string.format('%q', key)
		else key = tostring(key) end
		if value_type == "table" then
			value = mfr.prettify_table(value, _recursion_level)
		elseif value_type == "string" then value = string.format('%q', value)
		else value = tostring(value) end
		nice_msg = nice_msg .. tabulation .. key .. " = " .. value .. ",\n"
	end
	return nice_msg .. string.rep("\t", _recursion_level - 1) .. "}"
end

--- make a good-looking string out of anything.
-- @usage
-- perfect_table = {1, 2, a = {"text1", "text2"}}
-- mfr.pprint(perfect_table)
-- @param object anything to be pretty-printed
-- @within prettifyers
function mfr.pprint(object)  -- io operations, not to be tested
	local object_type, result = type(object)
	if object_type == "table" then result = mfr.prettify_table(object, 0)
	else result = tostring(object) end
	io.write(result)
end



--- create frame with message in terminal.
-- note that all tabs will be converted to character sequence defined by
-- `set_tab_representation` - 4 spaces is a default value.
-- please, note that pattern param is cut, and only its 1st symbol is used.
-- @tparam string message text to be displayed
-- @tparam number width width of the frame
-- @tparam string pattern pattern to be used to create frame
-- @treturn string framed message
-- @raise if message is not a string, or width is not a number, or pattern is
-- not a string
-- @see mfr.set_tab_representation
-- @see mfr.create_line_borders
-- @see mfr.create_page_borders
-- @within prettifyers
function mfr.create_frame(message, width, pattern)
	if type(message) == "table" and not width then
		pattern, width = message.pattern, message.width
		message = message.message
	end
	if pattern == "" then pattern = "*" end
	pattern, width = pattern or "*", width or 80
	assert(type(message) == "string", "message is string")
	assert(type(width) == "number", "width is number")
	assert(type(pattern) == "string", "pattern is string")
	message = message:gsub("\t", mfr._TAB_REPRESENTATION)
	local top = string.rep(pattern, width) .. "\n"
	return top .. mfr.create_page_borders(message, width, pattern) .. top
end

--- create line borders.
-- note that all tabs will be converted to character sequence defined by
-- `set_tab_representation` - 4 spaces is a default value.
-- please, note that border param is cut, and only its 1st symbol is used.
-- @tparam string text text to be displayed put inside borders
-- @tparam number length length of the frame
-- @tparam string border border to put text into
-- @treturn string bordered text
-- @raise if text is not a string, or length is not a number, or border is not
-- a string
-- @see mfr.set_tab_representation
-- @see mfr.create_frame
-- @see mfr.create_page_borders
-- @within prettifyers
function mfr.create_line_borders(text, length, border)
	if type(text) == "table" and not length then
		border, length = text.border, text.length
		text = text.text
	end
	length, border = length or 80, border or "*"
	border = border:sub(1)
	assert(type(text) == "string", "text is string")
	assert(type(length) == "number", "length is number")
	assert(type(border) == "string", "pattern is string")
	assert(length > 4, "length is larger than 4")
	text = text:gsub("\t", mfr._TAB_REPRESENTATION)
	assert(length - text:len() > 4, "text is shorter than length by 4")
	local spacing = string.rep(" ", length - 3 - text:len())
	return border .. " " .. text .. spacing .. border .. "\n"
end

--- create page borders.
-- note that all tabs will be converted to character sequence defined by
-- `set_tab_representation` - 4 spaces is a default value.
-- please, note that pattern param is cut, and only its 1st symbol is used.
-- @tparam string message message to be displayed put inside borders
-- @tparam number width width of the page
-- @tparam string pattern border pattern to put message into
-- @treturn string bordered page of text
-- @raise if message is not a string
-- @see mfr.set_tab_representation
-- @see mfr.create_frame
-- @see mfr.create_line_borders
-- @within prettifyers
function mfr.create_page_borders(message, width, pattern)
	if type(message) == "table" and not width and not pattern then
		pattern, width = message.pattern, message.width
		message = message.message
	end
	assert(type(message) == "string", "message argument is string")
	local character, next_space_coord
	local next_space, result, temp = 0, "", ""
	message = message:gsub("\t", mfr._TAB_REPRESENTATION)
	for character_index = 1, message:len() do
		character = message:sub(character_index, character_index)
		if character == " " then
			next_space_coord = string.find(message, " ", character_index + 1)
			next_space_coord = next_space_coord or message:len()
			next_space = next_space_coord - character_index
		elseif character == "\n" then
			result = result .. mfr.create_line_borders(temp, width, pattern)
			temp, next_space = "", 0
		end
		if next_space + temp:len() > width - 4 then
			result = result .. mfr.create_line_borders(temp, width, pattern)
			temp, next_space = "", 0
		end
		if character ~= "\n" then temp  = temp .. character end
		next_space = next_space - 1
	end
	if temp ~= "" then
		result = result .. mfr.create_line_borders(temp, width, pattern)
	end
	return result
end

--- @section showing

--- send available foreground colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_fg_colors(is_forced)
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
	local result, default_style, temp = "", mfr._FG_COLORS.default, {}
	if mfr._cache._FG_COLORS_STRING then io.write(mfr._cache._FG_COLORS_STRING)
		return; end
	local key_length, value_table
	local max_key_len = 0
	for key, value in pairs(mfr._FG_COLORS) do
		key_length = key:len()
		if key_length > max_key_len then max_key_len = key_length end
		value_table = {color_name = key, value = value}
		table.insert(temp, value_table)
	end
	table.sort(temp, compare)
	for _, color in pairs(temp) do
		local tab = string.rep(" ", max_key_len - color.color_name:len())
		result = result .. color.value .. color.color_name .. tab .. " = "
		result = result .. color.value:sub(2) .. default_style .. "\n"
	end
	mfr._cache._FG_COLORS_STRING = result
	io.write(mfr._cache._FG_COLORS_STRING)
end

--- send available background colors to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_bg_colors(is_forced)
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
	if mfr._cache._BG_COLORS_STRING then io.write(mfr._cache._BG_COLORS_STRING)
		return; end
	local result, default_style, temp = "", mfr._BG_COLORS.default, {}
	local key_length, value_table
	local max_key_len = 0
	for key, value in pairs(mfr._BG_COLORS) do
		key_length = key:len()
		if key_length > max_key_len then max_key_len = key_length end
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
	io.write(mfr._cache._BG_COLORS_STRING)
end

--- send available special styles to stdout.
-- @tparam boolean is_forced if true, output is provided even if terminal does 
-- not support colors.
-- @raise if colors are not supported and is_forced is not true
-- @within showing
function mfr.describe_special_styles(is_forced)
	assert(is_forced or mfr.is_supporting_colors(), "no support for colors")
	if mfr._cache._SPECIAL_STYLES_STRING then
		io.write(mfr._cache._SPECIAL_STYLES_STRING); return; end
	local key_length
	local result, max_key_len = "", 0
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
	io.write(mfr._cache._SPECIAL_STYLES_STRING)
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
	local error_message = "value is signed number argument"
	assert(value > 0, error_message)
	mfr._MAX_RECURSION = value
end

--- get maximal recursion level.
-- @treturn number maximal recursion level
-- @see mfr.set_max_recursion
-- @within settings
function mfr.get_max_recursion() return mfr._MAX_RECURSION end

--- set tab representation.
-- for instance, tab representation "    " (default value) means that tab 
-- symbol will be substituted for 4 spaces in functions that need tab to have 
-- stable length.
-- @raise error if value param is not a string.
-- @tparam string value new tab representation
-- @see mfr.get_tab_representation
-- @within settings
function mfr.set_tab_representation(value)
	assert(type(value) == "string", "value is string")
	mfr._TAB_REPRESENTATION = value
end

--- get tab representation.
-- @treturn string current tab representation
-- @see mfr.set_tab_representation
-- @within settings
function mfr.get_tab_representation() return mfr._TAB_REPRESENTATION end

return mfr