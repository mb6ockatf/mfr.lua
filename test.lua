#!/usr/bin/env lua
IS_UNDER_TESTING = true
DIFFERENT_TYPE_ARGS = {123, "random stuff", "text", nil, {}}
math.randomseed(os.time())

local function split(str, separator)
	if separator == nil then separator = " "
	elseif type(separator) ~= "string" then
		error("separator argument must be string")
	end
	local character
	local result, buffer = {}, ""
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

local CHARSET = [[abcdefghijklmnopqrstuvwxyz\
ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890\n ]]

function string.random(length)
    local position
	local result = ""
    for _ = 1, length do
        position = math.random(1, #CHARSET)
        result = result .. CHARSET:sub(position, position)
    end
    return result
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

describe("test cut_string", function()
	it("fails if arguments are incorrect", function()
		assert.has_error(function() mfr.cut_string() end,
		"str argument is string")
		assert.has_errors(function() mfr.cut_string(12, "fish text") end,
		"str argument is string")
		assert.has_errors(function() mfr.cut_string("zebra text") end,
		"length argument is number")
		assert.has_errors(function() mfr.cut_string{length=3} end,
		"str argument is string")
	end)
	it("returns array: input string sliced by length", function()
		local text_16, text_32 = "text_text_text_1", string.random(32)
		local result_16  = mfr.cut_string(text_16, 4)
		local result_32 = mfr.cut_string(text_32, 5)
		local good_length_16, good_length_32 = 4, 5
		for _, value in ipairs(result_16) do
			assert.is_equal(value:len(), good_length_16)
		end
		for index=1, #result_32 - 1 do
			assert.is_equal(result_32[index]:len(), good_length_32)
		end
	end)
end)