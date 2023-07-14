#!/usr/bin/env lua
IS_UNDER_TESTING = true
DIFFERENT_TYPE_ARGS = {123, "random stuff", "text", nil, {}}
math.randomseed(os.time())

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

local CHARSET = "abcdefghijklmnopqrstuvwxyz\
ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890\n "

function string.random(length)
	local result
	if length > 0 then
		result = string.random(length - 1)
		result = result .. CHARSET:sub(math.random(1, #CHARSET), 1)
		return result
	else
		return ""
	end
end

require "busted.runner"()
expose("testing mfr module", function()
	mfr = require("mfr")
	it("can be loaded", function() assert.is_not_equal(mfr, nil) end)
end)

describe("test create_frame function", function()
	local arg_set = {{message="text", width=12, pattern="*"},
	{message="long text: many words, words..."},
	{message="long text: many words, words...",  pattern="?"},
	{message=string.random(15), width=120},
	{message=string.random(30), pattern=""}}
	it("exists", function()
		assert.is_equal(type(mfr.create_frame), "function")
	end)
	it("accepts 3 parameters, and 2 last are optional", function()
		assert.has_no.errors(function()
			for _, argument in ipairs(arg_set) do mfr.create_frame(argument) end
		end)
	end)
	it("cannot work without `message` argument", function()
		assert.has.errors(function() mfr.create_frame() end)
	end)
	it("returns string, and all returned lines are same length", function()
		local results = {}
		for _, argument in ipairs(arg_set) do
			table.insert(results, mfr.create_frame(argument))
		end
		local check = false
		for _1, value in ipairs(results) do
			if type(value) ~= "string" then check = true end
			local array = split(value, "\n")
			local length = array[1]:len()
			for _2, line in ipairs(array) do
				if line:len() ~= length then check = true end
			end
		end
		assert.is_equal(check, false)
	end)
	it("uses correct pattern", function()
		assert.is_equal(mfr.create_frame(arg_set[3]):sub(1, 1), "?")
	end)
end)

describe("test describe bg / fg / special colors functions", function()
	it("returns nil", function()
		function execute_system_command(command)
			if command == "tput colors" then return 7000 end
		end
		function os.getenv(variable)
			if variable == "NO_COLOR" then return nil end
		end
		assert.is_equal(nil == mfr.describe_bg_colors(), true)
		assert.is_equal(nil == mfr.describe_fg_colors(), true)
		assert.is_equal(nil == mfr.describe_special_styles(), true)
	end)
	it("raises an error if terminal does not like colors", function()
		function mfr.is_supporting_colors() return false end
		function check_all_return_errors_due_to_terminal_answer()
			mfr._cache._IS_SUPPORTING_COLORS = nil
			local colors_error = "terminal does not support colors"
			local styles_error = "terminal does not support special styles"
			mfr._cache._IS_SUPPORTING_COLORS = nil
			assert.has_errors(function() mfr.describe_fg_colors() end, 
				colors_error)
			mfr._cache._IS_SUPPORTING_COLORS = nil
			assert.has_errors(function() mfr.describe_bg_colors() end, 
				colors_error)
			mfr._cache._IS_SUPPORTING_COLORS = nil
			assert.has_errors(function() mfr.describe_special_styles() end,
				styles_error)
			mfr._cache._IS_SUPPORTING_COLORS = nil
		end
		check_all_return_errors_due_to_terminal_answer()
	end)
end)

describe("test clear_screen function", function()
	local io_write_original, io_flush_original = io.write, io.flush
	io.write = spy.new(function(text) io["storage"] = text end)
	io.flush = spy.new(function() end)
	it("outputs right ascii control sequence", function()
		mfr.clear_screen()
		assert.spy(io.write).was_called_with("\27[3J\27[H\27[2J")
		assert.spy(io.flush).was_called(1)
		assert.is_same("\27[3J\27[H\27[2J", io["storage"])
	end)
end)
