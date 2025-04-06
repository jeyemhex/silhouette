#!/usr/bin/env lua
--[[ LIBRARY_MANAGER
--------------------------------------------------------------------------------
    Author:  Ed Higgins <ed.j.higgins@gmail.com>
--------------------------------------------------------------------------------
    Version: 0.1.1, 2025-04-05
--------------------------------------------------------------------------------
    This code is distributed under the MIT license.
----------------------------------------------------------------------------- ]]
local libm = require "core/library_manager"

function main()
    libm.initialise(arg[1], "music_library.sqlite")
end

main()
