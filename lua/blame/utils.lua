local M = {}

---Calculates the longest string in the string[]
---@param string_array string[]
---@return integer
M.longest_string_in_array = function(string_array)
    local longest = 0
    for _, value in ipairs(string_array) do
        if vim.fn.strdisplaywidth(value) > longest then
            longest = vim.fn.strdisplaywidth(value)
        end
    end
    return longest
end

M.pattern_to_stamp = function (pattern, date_str)
    local year, month, day, hour, min, sec = date_str:match(pattern)

    -- Create a table for os.time
    local date_table = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    }

    return os.time(date_table)
end


-- local function execute_command(command, cwd, callback, err_cb)
--     local data
--     local err_data
--     vim.fn.jobstart(command, {
--         cwd = cwd,
--         on_exit = function(_, exit_code)
--             if exit_code ~= 0 then
--                 return err_cb(table.concat(err_data, " "))
--             end
--             callback(data)
--         end,
--         on_stderr = function(_, d)
--             err_data = d
--         end,
--         on_stdout = function(_, d)
--             data = d
--         end,
--         stdout_buffered = true,
--         stderr_buffered = true,
--     })
-- end

-- M.extrive_svn_message = function(cwd, revision)
--     local revision_int = math.tointeger(revision)
--     if type(revision_int) ~= 'number' then
--         return 
--     end
--
--     local commands = {
--         "svn",
--         "log",
--         "-r",
--         revision
--     }
--
--     execute_command(commands, cwd, function (data)
--
--     end)
--
-- end

return M
