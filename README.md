# mfr.lua

output formatter written in lua

download this module via luarocks: `luarocks install mfr`

import with `mfr = require("mfr")`

use any functions from [docs/index.html](docs/index.html):
```lua
mfr.describe_fg_colors()
```

documentation also awailable on [github pages](https://mb6ockatf.github.io/mfr.lua/)

## unittests

unittests are written with [`busted`](https://github.com/lunarmodules/busted).
launch them with `./test.lua`. please, note that system-dependent tests are
not run (i.e. if your terminal does not support colors, corresponding 
functionality is not going to be checked). output functions are not tested,
too.

## contrubution

this repository is open for contribution. you're welcome to submit ideas & bug
reports at *issues* tab, too

## license

Copyright (C) 2023-2024 mb6ockatf

mfr.lua is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.  See COPYING.LESSER and COPYING.
