local common = require('blame.common')
local xml = require("pl.xml")
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
        for _, entry in ipairs(blame_porcelain) do
            local ident = entry:match("^%S+")
            if not ident then
                all_lines[#all_lines].content = entry
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
        vim.notify(type(blame_porcelain), vim.log.levels.INFO)
        vim.notify(blame_porcelain[1], vim.log.levels.INFO)

        template = [[
            <entry
               line-number="16795">
            <commit
               revision="490193">
            <author>grantliao</author>
            <date>2024-09-29T07:24:04.714887Z</date>
            </commit>
            </entry> 
        ]]

        local blame_xml = xml.parse(table.concat(blame_porcelain, '\n'))
        for _, entry in ipairs(blame_xml:get_elements_with_name("entry")) do

            local commit = entry:child_with_name('commit')
            local author = commit:child_with_name('author')
            local date   = commit:child_with_name('date')

            local line_info = {
                line_number = entry.attr['line-number'],
                hash = commit.attr['revision'],
                author = author:get_text(),
                date = date:get_text(),
            }

            vim.notify(string.format("hash=%s, author=%s, content=, author_time=%s", 
                line_info.hash, line_info.author, line_info.author_time), vim.log.levels.INFO)
            table.insert(all_lines, line_info)
        end
    end
    return all_lines
end

return M
