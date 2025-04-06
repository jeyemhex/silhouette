--[[ LIBRARY_MANAGER
--------------------------------------------------------------------------------
    Author:  Ed Higgins <ed.j.higgins@gmail.com>
--------------------------------------------------------------------------------
    Version: 0.1.1, 2025-04-05
--------------------------------------------------------------------------------
    This code is distributed under the MIT license.
----------------------------------------------------------------------------- ]]
local lfs = require "lfs"
local dbm = require "core/database_manager"

local library_manager = {}

function library_manager.initialise(path, db_file)
    local metadata = get_media_files(path)
    dbm.initialise_db(db_file)
    dbm.add_tracks(db_file, metadata)
end

function get_media_files(path)
    local media_files = {}
    for filename in lfs.dir(path) do
        if filename ~= "." and filename ~= ".." then
            local file = path .. "/" .. filename
            local mode = lfs.attributes(file, "mode")

            if mode == "directory" then
                for _,f in ipairs(get_media_files(file)) do
                    table.insert(media_files, f)
                end

            elseif mode == "file" then
                local f_ext = file:match("^.+%.(.+)$")
                if f_ext == "flac" then
                    local metadata = get_flac_metadata(file)
                    if metadata ~= nil then
                        metadata.file = file
                        table.insert(media_files, metadata)
                    end
                end

            else
                error()
            end

        end
    end

    return media_files
end

function get_flac_metadata(file)
    local metadata = {
        artist = nil,
        albumartist = nil,
        album = nil,
        title = nil
    }

    local sanitised = file:gsub('"', '\\"')
    sanitised = sanitised:gsub('%$', '\\$')
    sanitised = sanitised:gsub('`', '\\`')
    --sanitised = sanitised:gsub('!', '\\!')
    local command = 'metaflac --show-all-tags "' .. sanitised .. '"'
    local attempts = 0
    ::attempt::
    local handle = io.popen(command)
    if handle then
        for line in handle:lines() do
            local key,value = line:match("([^=]+)=(.*)$")
            if not (key == nil or key:match("^MUSICBRAINZ") or key:match("sort$")) then
                metadata[key:lower()] = value
            end
        end

        if metadata.artist == nil then
            if metadata.albumartist ~= nil then
                metadata.artist = metadata.albumartist
            else
                error("Artist tag missing in " .. file)
            end
        end

        if metadata.albumartist == nil then metadata.albumartist = metadata.artist end

        return metadata
    else
        attempts = attempts + 1
        if attempts > 0 then
            print("^Failed to read " .. file)
            return nil
        else
            os.execute("sleep 1")
            goto attempt
        end
    end
end


return library_manager
