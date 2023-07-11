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
expose("create_frame", function()
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


--[[
	describe("pprint function works fine", function()
		it("always returns nil", function()
			for _, value in ipairs(DIFFERENT_TYPE_ARGS) do
				assert.is_equal(mfr.pprint(value), nil)
			end
			assert.is_equal(mfr.pprint(), nil)
		end)
	end)
	describe("prettify table works fine", function()
		it("accepts empty table", function()
			assert.is_equal(mfr.prettify_table({}), "{\n}\n")
		end)
		it("accepts any kinds of tables", function()
			local array = {1, 2, 3}
			assert.is_not_equal(mfr.prettify_table(array), nil)
			local dictionary = {a = 1, b = 2, c = 3, text = "giga biggy text"}
			assert.is_not_equal(mfr.prettify_table(dictionary), nil)
		end)
	end)
end)
--]]