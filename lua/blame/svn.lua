local common = require('blame.common')


---@class Svn
---@field config Config
local SVN = {}

---@return SVN
function SVN:new(config)
    local o = {}
    setmetatable(o, { __index = self })
    o.config = config
    return o
end

local function execute_command(command, cwd, callback, err_cb)
    local data
    local err_data
    vim.fn.jobstart(command, {
        cwd = cwd,
        on_exit = function(_, exit_code)
            if exit_code ~= 0 then
                return err_cb(table.concat(err_data, " "))
            end
            callback(data)
        end,
        on_stderr = function(_, d)
            err_data = d
        end,
        on_stdout = function(_, d)
            data = d
        end,

        stdout_buffered = true,
        stderr_buffered = true,
    })
end

local function add_blame_options(blame_command, blame_options)
    if blame_options == nil then
        return
    end

    local index = #blame_command - 2
    for i = 1, #blame_options do
        table.insert(blame_command, index + i, blame_options[i])
    end
end

---Execute svn blame command, returns output string
---@param filename string the file to blame
---@param cwd any the working directory where the command will be executed
---@param revision string|nil the specific revision to blame
---@param callback fun(data: string[]) callback on exiting the command with output string
---@param err_cb fun(error: string) callback in case of an error
function SVN:blame(filename, cwd, revision, callback, err_cb)
    local blame_command = {
        "svn",
        "blame",
        "-x",
        "--ignore-eol-style",
        "--force",
        "-v",
    }

    add_blame_options(blame_command, self.config.blame_options)

    if revision ~= nil then
        table.insert(blame_command, "-r")
        table.insert(blame_command, revision)
    end

    table.insert(blame_command, filename)

    -- Execute the command
    execute_command(blame_command, cwd, callback, err_cb)
end

function SVN:svn_root(cwd, callback, err_cb)
    local rev_parse_command = { "svn", "info", "--xml" }
    execute_command(rev_parse_command, cwd, callback, err_cb)
end

---Execute git show
---@param file_path string|nil relative file path
---@param cwd any cwd where to execute the command
---@param commit string
---@param callback fun(data: string[]) callback on exiting the command with output string
function SVN:show(file_path, cwd, commit, callback, err_cb)
    local show_command = { "svn", "cat", "-r" }

    if file_path then
        -- show_command = show_command .. ":" .. file_path
        table.insert(show_command, commit)
        table.insert(show_command, file_path)
        execute_command(show_command, cwd, callback, err_cb)
    else
        table.insert(show_command, commit)
        execute_command(show_command, cwd, callback, err_cb)
    end
end

SVN.working_copy = _G.WORKING_COPY_SVN
return SVN
