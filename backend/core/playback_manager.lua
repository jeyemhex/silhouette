--[[ PLAYBACK_MANAGER
--------------------------------------------------------------------------------
    Author:  Ed Higgins <ed.j.higgins@gmail.com>
--------------------------------------------------------------------------------
    Version: 0.1.1, 2025-04-09
--------------------------------------------------------------------------------
    This code is distributed under the MIT license.
----------------------------------------------------------------------------- ]]
UNLOADED  = 0
STOPPED   = 1
PAUSED    = 2
PLAYING   = 3

local playback_manager = {
    filename = "",
    audio_data = "",
    state = UNLOADED,
    buffer_length = 0,
    cursor = 0,
    player = nil,
}

function playback_manager:new (o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function playback_manager:load(filename)
    self.filename = filename
    local flac = io.popen("flac -c -d 2> /dev/null '" .. filename .. "'")
    self.audio_data = flac:read("*a")
    flac:close()
end

function playback_manager:start()
    if not self.player then
        self.player = io.popen("aplay 2> /dev/null", "w")
        self.buffer_length = 2^12
    end

    self.cursor = 1
    self.state = PLAYING
end

function playback_manager:play()
    if self.cursor < self.audio_data:len() then
        self.player:write(self.audio_data:sub(self.cursor, self.cursor+self.buffer_length-1))
        self.cursor = self.cursor + self.buffer_length
    else
        self:stop()
    end
end

function playback_manager:stop()
    self.cursor = 1
    self.state = STOPPED
    self:player:close()
end

function playback_manager:unload()
    self.filename = ""
    self.audio_data = ""
    self.state = UNLOADED
    self.buffer_length = 0
    self.cursor = 0
    self.player = nil
end

return playback_manager
