package = "mfr"
version = "1.0-3"
source = {
   url = "git+https://github.com/mb6ockatf/mfr.lua.git"
}
description = {
   summary = "output formatter",
   detailed = "simple lua module with functions for output prettifying",
   homepage = "https://mb6ockatf.github.io/mfr.lua/",
   license = "LGPL-3.0-or-later"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      mfr = "mfr.lua"
   }
}
