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
local playm = require "core/playback_manager"

function main()
    local current_song = playm:new()
    current_song:load(arg[1])

    current_song:start()

    while current_song.state == PLAYING do
        current_song:play()
    end

    current_song:unload()
end

main()
