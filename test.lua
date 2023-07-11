#!/usr/bin/env lua
IS_UNDER_TESTING = true
DIFFERENT_TYPE_ARGS = {123, "random stuff", "text", nil, {}}
require "busted.runner"()
describe("testing mfr module", function()
	setup(function() mfr = require("mfr") end)
	it("can be loaded", function()
		assert.is_not_equal(mfr, nil)
	end)
	it("module constants are not accessible", function()
		assert.is_equal(MAX_RECURSION, nil)
	end)
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