-- .luacheckrc - luacheck settings for mfr.lua and its tests.
--
-- mfr is a global by design; the tests use busted and set a few
-- globals of their own.  .lua/ and .luarocks/ are where CI installs
-- Lua and the rocks.

std = "max"
globals = {"mfr"}
ignore = {"614", "213/_.*"}
exclude_files = {".lua/**", ".luarocks/**", ".install/**"}

files["mfr.lua"] = {
	ignore = {"311/result"},
}

files["test.lua"] = {
	std = "+busted",
	globals = {
		"IS_UNDER_TESTING", "DIFFERENT_TYPE_ARGS", "INITIAL_VALUE",
		string = {fields = {"random"}},
	},
}
