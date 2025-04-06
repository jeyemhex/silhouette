--[[ LIBRARY_MANAGER
--------------------------------------------------------------------------------
    Author:  Ed Higgins <ed.j.higgins@gmail.com>
--------------------------------------------------------------------------------
    Version: 0.1.1, 2025-04-05
--------------------------------------------------------------------------------
    This code is distributed under the MIT license.
----------------------------------------------------------------------------- ]]
local luasql = require("luasql.sqlite3")

local database_manager = {}

function database_manager.initialise_db(db_file)
    local db_env = luasql.sqlite3()
    local db_con = db_env:connect(db_file)
    sql(db_con, "PRAGMA foreign_keys = ON;")

    -- Enable foreign keys in our DB

    -- Create the artists table
    sql(db_con, [[
        CREATE TABLE IF NOT EXISTS artists (
            artist_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE COLLATE NOCASE
        );
    ]])

    -- Create the albums table
    sql(db_con, [[
        CREATE TABLE IF NOT EXISTS albums (
            album_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE,
            artist_id INTEGER NOT NULL,
            release_year INTEGER,
            FOREIGN KEY (artist_id) REFERENCES artists (artist_id) ON DELETE CASCADE,
            UNIQUE (name, artist_id)
        );
    ]]);

    -- Create the tracks table
    sql(db_con, [[
        CREATE TABLE IF NOT EXISTS tracks (
            track_id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL COLLATE NOCASE,
            album_id INTEGER NOT NULL,
            track_artist_id INTEGER NOT NULL,
            filepath TEXT NOT NULL UNIQUE,
            track_number INTEGER,
            FOREIGN KEY (album_id) REFERENCES albums (album_ID) ON DELETE CASCADE,
            FOREIGN KEY (track_artist_id) REFERENCES artists (artist_id) ON DELETE RESTRICT
        );
    ]]);

    -- Create indexes for common searches
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_artist_name ON artists (name);");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_album_name ON albums (name);");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_album_artist_id ON albums (artist_id);");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_track_title ON tracks (title);");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_track_album_id ON tracks (album_id)");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_track_artist_id ON tracks (track_artist_id)");
    sql(db_con, "CREATE INDEX IF NOT EXISTS idx_track_filepath ON tracks (filepath)");

    db_con:close()
    db_env:close()
end

function database_manager.get_artist_id(db_con, artist_name)
    return sql_get_scalar(db_con,
        "SELECT artist_id FROM artists WHERE name = " .. sanitise(artist_name)
    )
end

function database_manager.get_album_id(db_con, album_name, album_artist_id)
    return sql_get_scalar(db_con,
        "SELECT album_id FROM albums WHERE name    = " .. sanitise(album_name)
                                .. " AND artist_id = " .. album_artist_id
    )
end

function database_manager.add_tracks(db_file, tracks_metadata)
    local db_env = luasql.sqlite3()
    local db_con = db_env:connect(db_file)

    for _,track in ipairs(tracks_metadata) do
        local album_artist_id = database_manager.get_artist_id(db_con, track.albumartist)
                       or add_artist(db_con, track.albumartist)

        local track_artist_id = database_manager.get_artist_id(db_con, track.artist)
                       or add_artist(db_con, track.artist)

        local album_id = database_manager.get_album_id(db_con, track.album, album_artist_id)
                       or add_album(db_con, track.album, album_artist_id, track.date)

        sql(db_con, [[
            INSERT OR IGNORE INTO tracks
            (title, album_id, track_artist_id, filepath, track_number)
            VALUES (]]
                .. sanitise(track.title) .. ", "
                .. album_id .. ", "
                .. track_artist_id .. ", "
                .. sanitise(track.file) .. ", "
                .. track.tracknumber ..  ")"
        );
    end

    db_con:close()
    db_env:close()
end

function add_artist(db_con, artist_name)
    sql(db_con, "INSERT INTO artists (name) VALUES (" .. sanitise(artist_name) ..")")
    return sql_get_scalar(db_con, "SELECT last_insert_rowid()")
end

function add_album(db_con, album_name, artist_id, release_year)
    sql(db_con, "INSERT INTO albums (name, artist_id, release_year) VALUES ("
        .. sanitise(album_name) ..", "
        .. artist_id ..", "
        .. (release_year or "NULL") ..")"
    )
    return sql_get_scalar(db_con, "SELECT last_insert_rowid()")
end

function sanitise(str)
    if str then
        local sane = str:gsub("'", "''")
        return "'"..sane.."'"
    else
        return "NULL"
    end
end

function sql(db_connection, command)
    local result, err = db_connection:execute(command)
    if not result then
        err = err or "Unknown error"
        print("SQL ERROR: " .. err)
        print("    on command: " .. command)
        error()
    end

    return result
end

function sql_get_scalar(db_connection, command)
    local cursor = sql(db_connection, command)
    local row = cursor:fetch({},"n")
    cursor:close()

    if row and row[1] ~= nil then
        return row[1]
    end
end

return database_manager
