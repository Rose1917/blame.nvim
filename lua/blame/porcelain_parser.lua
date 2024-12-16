local common = require('blame.common')
local xml = require("pl.xml")
local util = require('blame.utils')
local M = {}

---@class Porcelain
---@field author string
---@field author_email string
---@field author_time number
---@field author_tz string
---@field committer string
---@field committer_mail string
---@field committer_time number
---@field committer_tz string
---@field filename string
---@field hash string
---@field previous string|nil
---@field summary string
---@field content string

---Parses raw porcelain data (string[]) into an array of tables for each line containing the commit data
---@param blame_porcelain string[]
---@return Porcelain[]
M.parse_porcelain = function(blame_porcelain, vcs)

    local all_lines = {}

    if vcs == _G.WORKING_COPY_GIT then
        --[[
        dc5db56796ee593423e93d234f64850e922808da 6 6
        author pedroren
        author-mail <pedroren@tencent.com>
        author-time 1729733821
        author-tz +0800
        committer pedroren
        committer-mail <pedroren@tencent.com>
        committer-time 1729733821
        committer-tz +0800
        summary init
        boundary
        filename src/cli.rs
            #[derive(Debug, Clone, Copy)]
        ]]
        for _, entry in ipairs(blame_porcelain) do
            local ident = entry:match("^%S+")
            -- vim.notify(entry, vim.log.levels.ERROR)
            if not ident then
                all_lines[#all_lines].content = entry
                -- vim.notify('not ident'..entry, vim.log.levels.INFO)
            elseif #ident == 40 then
                table.insert(all_lines, { hash = ident })
            else
                ident = ident:gsub("-", "_")

                local info = string.sub(entry, #ident + 2, -1)
                if ident == "author_time" or ident == "committer_time" then
                    all_lines[#all_lines][ident] = tonumber(info)
                else
                    all_lines[#all_lines][ident] = info
                end
            end
        end
    end

    if vcs == _G.WORKING_COPY_SVN then
        -- Parse SVN blame XML output
        local line_num = 1
        for _, entry in ipairs(blame_porcelain) do
            local pattern = "(%d+)%s+(%S+)%s+([%d%-]+%s+[%d:]+)%s+[%+%-]%d+%s+%([^%)]+%)%s*(.*)"
            local hash, author, date, content = entry:match(pattern)
            local date_stamp

            if hash == nil then
                hash = '0000000000000000000000000000000000000000'
                author = 'Not Committed Yet'
                date_stamp = os.time()
            else 
                date_stamp = util.pattern_to_stamp("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)", date)
            end

            local line_info = {
                line_number = line_num,
                hash = hash,
                author = author,
                committer_time = date_stamp,
                author_time = date_stamp,
            }
            table.insert(all_lines, line_info)
            line_num = line_num + 1
        end
    end
    return all_lines
end

return M
