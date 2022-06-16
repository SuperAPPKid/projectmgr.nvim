-- Imports the plugin's additional Lua modules.
local fetch = require("projectmgr.fetch")
local update = require("projectmgr.update")



local api = vim.api
local buf, win
local position = 0

local function open_window()
    buf = api.nvim_create_buf(false, true)

    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(buf, 'filetype', 'projectmgr')

    -- get dimensions
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    -- calculate our floating window size
    local win_height = math.ceil(height * 0.25 - 4)
    local win_width = math.ceil(width * 0.15)

    -- and its starting position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- set some options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = {"╔", "═" ,"╗", "║", "╝", "═", "╚", "║"}
    }

    -- and finally create it with buffer attached
    win = api.nvim_open_win(buf, true, opts)
    api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

    -- we can add title already here, because first line will never change
    api.nvim_buf_set_lines(buf, 0, -1, false, { ' [Projects]', '', ''})
    api.nvim_buf_add_highlight(buf, -1, 'ProjectmgrHeader', 0, 0, -1)
end

local function update_view(direction)
    api.nvim_buf_set_option(buf, 'modifiable', true)
    position = position + direction
    if position < 1 then position = 1 end

    local flattened = fetch.get_projects()
    for k,_ in pairs(flattened) do
        flattened[k] = '  '..flattened[k]
    end

    api.nvim_buf_set_lines(buf, 3, -1, false, flattened)
    api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
    api.nvim_win_close(win, true)
end

local function delete_project()
    local str = api.nvim_get_current_line()
    local name = str:gsub(" ", "")
    update.delete_project(name)
    update_view(0)
end

local function open_project()
    local str = api.nvim_get_current_line()
    local name = str:gsub(" ", "")
    close_window()
    local new_wd,command = fetch.get_single_project(name)
    if new_wd ~= nil then
        api.nvim_command('cd '..new_wd)
        if command ~= nil then
            api.nvim_command(command)
        end
    end
end

local function set_mappings()
    local mappings = {
        -- ['['] = 'update_view(-1)',
        -- [']'] = 'update_view(1)',
        ['<cr>'] = 'open_project()',
        ['x'] = 'delete_project()',
        -- h = 'update_view(-1)',
        -- l = 'update_view(1)',
        ['q'] = 'close_window()',
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"projectmgr".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
    local other_chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'y', 'z'
    }
    for _,v in ipairs(other_chars) do
        api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
        api.nvim_buf_set_keymap(buf, 'n',  '<c-'..v..'>', '', { nowait = true, noremap = true, silent = true })
    end
end

local function show_selection()
    position = 0
    open_window()
    set_mappings()
    update_view(0)
    api.nvim_win_set_cursor(win, {4, 0})
end

-- Creates an object for the module. All of the module's
-- functions are associated with this object, which is
-- returned when the module is called with `require`.
local M = {}

-- Routes calls made to this module to functions in the
-- plugin's other modules.
M.show_selection = show_selection
M.open_project = open_project
M.delete_project = delete_project
M.close_window = close_window
M.create_project = update.create_project

return M
