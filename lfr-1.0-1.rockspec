package = "lfr"
version = "1.0-1"
source = {url = "git://github.com/mb6ockatf/lfr", tag="v1.0-1"}
description = {summary = "lua output formatter",
detailed = [[simple lua module with functions for output prettifying]],
homepage = "https://github.com/mb6ockatf/lfr", license = "AGPL-3.0"}
dependencies = {"lua >= 5.1"}
build = {type = "builtin", modules = {lfr = "lfr.lua"}}