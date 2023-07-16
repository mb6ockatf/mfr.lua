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

describe("create_frame", function()
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

describe("cut_string", function()
	it("fails if arguments are incorrect", function()
		local str_error = "str argument is string"
		assert.has_error(function() mfr.cut_string() end, str_error)
		assert.has_errors(function() mfr.cut_string(12, "fish text") end,
		str_error)
		assert.has_errors(function() mfr.cut_string("zebra text") end,
		"length argument is number")
		assert.has_errors(function() mfr.cut_string{length=3} end, str_error)
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

describe("deepcopy", function()
	it("returns right copy", function()
		assert.are_same(DIFFERENT_TYPE_ARGS, mfr.deepcopy(DIFFERENT_TYPE_ARGS))
		local table_with_folding = {}
		table_with_folding["elephant"] = {1, 2, 3, 4, moon = {71, 72, 73, 74}}
		assert.are_same(table_with_folding, mfr.deepcopy(table_with_folding))
	end)
	it("returns unchanged value if it is not a table", function()
		for _, arg in ipairs(DIFFERENT_TYPE_ARGS) do
			assert.is_equal(arg, mfr.deepcopy(arg))
		end
	end)
end)

describe("belongs", function()
	it("fails if arguments are incorrect", function()
		local error = "sequence is table"
		assert.has_error(function() mfr.belongs() end, error)
		assert.has_error(function() mfr.belongs(nil, nil) end, error)
	end)
	it("works", function()
		local example_array = {1, 2, 3, 4, nil, 6, 7, 8, 9, 10}
		assert.is_true(mfr.belongs(1, example_array))
		assert.is_false(mfr.belongs(11, example_array))
		assert.is_true(mfr.belongs(nil, example_array))
		assert.is_false(mfr.belongs(example_array, {}))
	end)
end)

describe("split", function()
	it("fails if arguments are incorrect", function()
		assert.has_error(function() mfr.split() end, "str argument is string")
		assert.has_error(function() mfr.split(nil, "e") end,
		"str argument is string")
		assert.has_no.error(function() mfr.split("text text") end)
	end)
	it("works", function()
		assert.are_same({"text", "text"}, mfr.split("text text"))
		assert.are_same({"elephant", "walrus"},
		mfr.split("elephant & walrus", " & "))
	end)
end)

describe("execute_system_command", function()
	it("fails if arguments are incorrect", function()
		local error = "command argument is string"
		assert.has_error(function() mfr.execute_system_command() end, error)
		assert.has_error(function() mfr.execute_system_command(123) end, error)
		assert.has_no.error(function() mfr.execute_system_command("echo 1") end)
	end)
end)
describe("color setting", function()
	if mfr.is_supporting_colors() then
		it("set_bg works", function()
			local arguments = {message = "message", color = "red",
			is_closed = true}
			local result
			assert.has_no.errors(function() result = mfr.set_bg(arguments) end)
			assert.is_equal("\27[41mmessage\27[49m", result)
			arguments.color = "magenta"
			assert.has_no.errors(function() result = mfr.set_bg(arguments) end)
			assert.is_equal("\27[45mmessage\27[49m", result)
			arguments.color, arguments.is_closed = "cyan", false
			assert.has_no.errors(function() result = mfr.set_bg(arguments) end)
			assert.is_equal("\27[46mmessage", result)
		end)
		it("set_fg works", function()
			local arguments = {message = "graduation diploma",
			color = "light_green"}
			local result
			assert.has_no.errors(function() result = mfr.set_fg(arguments) end)
			assert.is_equal("\27[92mgraduation diploma\27[39m", result)
			arguments.color = "light_blue"
			assert.has_no.errors(function() result = mfr.set_fg(arguments) end)
			assert.is_equal("\27[94mgraduation diploma\27[39m", result)
		end)
		it("set_special_style works", function()
			local arguments = {message = "looney tunes show",
			style = "negative"}
			local result
			assert.has_no.errors(function()
				result = mfr.set_special_style(arguments)
			end)
			assert.is_equal("\27[7mlooney tunes show\27[27m", result)
			arguments.style = "bold"
			assert.has_no.errors(function()
				result = mfr.set_special_style(arguments)
			end)
			assert.is_equal("\27[1mlooney tunes show\27[22m", result)
			arguments.style = "underline"
			assert.has_no.errors(function()
				result = mfr.set_special_style(arguments)
			end)
			assert.is_equal("\27[4mlooney tunes show\27[24m", result)
		end)
	end
end)

describe("prettify_table", function()
	it("works", function()
		local useless_list = {1, 2, a = {"text", "text"}}
		local right_answer = [[{
	1 = 1,
	2 = 2,
	"a" = {
		1 = "text",
		2 = "text",
	},
}]]
		assert.are_same(right_answer, mfr.prettify_table(useless_list))
	end)
end)

describe("set_max_recursion", function()
	setup(function() INITIAL_VALUE = mfr.get_max_recursion() end)
	it("fails if arguments are incorrect", function()
		local error = "value is signed number argument"
		local base_type_error = "attempt to compare number with "
		local nil_error = base_type_error .. "nil"
		local str_error = base_type_error .. "string"
		local table_error = base_type_error .. "table"
		assert.has_error(function() mfr.set_max_recursion() end, nil_error)
		assert.has_error(function() mfr.set_max_recursion("") end, str_error)
		assert.has_error(function() mfr.set_max_recursion({}) end, table_error)
		assert.has_error(function() mfr.set_max_recursion(-11) end, error)
		assert.has_error(function() mfr.set_max_recursion(0) end, error)
		assert.has_no.error(function() mfr.set_max_recursion(17) end)
	end)
	teardown(function()
		mfr.set_max_recursion(INITIAL_VALUE)
		INITIAL_VALUE = nil
	end)
end)

describe("get_max_recursion", function()
	setup(function() INITIAL_VALUE = mfr.get_max_recursion() end)
	it("works", function()
		mfr.set_max_recursion(221121)
		assert.is_equal(221121, mfr.get_max_recursion())
	end)
	teardown(function()
		mfr.set_max_recursion(INITIAL_VALUE)
		INITIAL_VALUE = nil
	end)
end)

describe("set_tab_representation", function()
	setup(function() INITIAL_VALUE = mfr.get_tab_representation() end)
	it("fails if arguments are incorrect", function()
		local error = "value is string"
		assert.has_error(function() mfr.set_tab_representation() end, error)
		assert.has_error(function() mfr.set_tab_representation(12) end, error)
		assert.has_error(function() mfr.set_tab_representation({}) end, error)
		assert.has_no.error(function() mfr.set_tab_representation("aboba") end)
	end)
	teardown(function()
		mfr.set_tab_representation(INITIAL_VALUE)
		INITIAL_VALUE = nil
	end)
end)

describe("get_tab_representation", function()
	setup(function() INITIAL_VALUE = mfr.get_tab_representation() end)
	it("works", function()
		mfr.set_tab_representation("221121")
		assert.is_equal("221121", mfr.get_tab_representation())
	end)
	teardown(function()
		mfr.set_tab_representation(INITIAL_VALUE)
		INITIAL_VALUE = nil
	end)
end)