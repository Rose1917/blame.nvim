local git = require("blame.git")
local svn = require("blame.svn")
local common = require("blame.common")
local window_view = require("blame.views.window_view")
local porcelain_parser = require("blame.porcelain_parser")
local virtual_view = require("blame.views.virtual_view")
local formats = require("blame.formats.default_formats")

---@class BlameView
---@field new fun(self, config:Config) : BlameView
---@field open fun(self, lines: Porcelain[])
---@field is_open fun(self): boolean
---@field close fun(self, cleanup: boolean)

---@alias FormatFn fun(line_porcelain: Porcelain, config:Config, idx:integer):LineWithHl

---@class Mappings
---@field commit_info string | string[]
---@field stack_push string | string[]
---@field stack_pop string | string[]
---@field show_commit string | string[]
---@field close string | string[]

---@class Config
---@field date_format? string Format of the output date
---@field views table<string, BlameView>
---@field focus_blame boolean Focus on the blame window when it's opened as well as blame stack push/pop
---@field merge_consecutive boolean Merge consecutive commits and don't repeat
---@field virtual_style 'float' | 'right_align' Style of the virtual view
---@field colors string[] | nil List of colors to use for highlights. If nill will use random RGB
---@field blame_options string[] | nil List of blame options to use for git blame. If nil will use no options
---@field format_fn FormatFn Function that formats the output, default: require("blame.formats.default_formats").date_message
---@field max_summary_width number Max width of the summary in 'date_summary' format
---@field commit_detail_view 'current' | 'tab' | 'vsplit' | 'split'
---@field mappings Mappings
local config = {
    date_format = "%d.%m.%Y",
    virtual_style = "right_align",
    views = {
        window = window_view,
        virtual = virtual_view,
        default = window_view,
    },
    focus_blame = true,
    merge_consecutive = false,
    max_summary_width = 30,
    colors = nil,
    blame_options = nil,
    format_fn = formats.commit_date_author_fn,
    commit_detail_view = "vsplit",
    mappings = {
        commit_info = "i",
        stack_push = "<TAB>",
        stack_pop = "<BS>",
        show_commit = "<CR>",
        close = { "<esc>", "q" },
    },
}


---@class Blame
---@field last_opened_view nil | BlameView
local M = {
    last_opened_view = nil,
}

---check if current buffer is under a git or svn vcs
local function check_vcs()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
    if vim.v.shell_error == 0 then
        return _G.WORKING_COPY_GIT, git_root[1] -- The current file is under a Git repository
    end

    local svn_info = vim.fn.systemlist("svn info 2>/dev/null")
    if vim.v.shell_error == 0 then
        return _G.WORKING_COPY_SVN, nil -- The current file is under an SVN repository
    end

    return nil, nil -- Not under any version control system
end

---@param blame_view BlameView
local function open(blame_view)
    local filename = vim.api.nvim_buf_get_name(0)
    local cwd = vim.fn.expand("%:p:h")
    if M.vcs == _G.WORKING_COPY_GIT then
        local g = git:new(config)
        g:blame(filename, cwd, nil,
            function(data)
                vim.schedule(function()
                    local parsed_blames = porcelain_parser.parse_porcelain(data, _G.WORKING_COPY_GIT)
                    blame_view:open(parsed_blames)
                end)
            end, 
            function(err)
                vim.notify(err, vim.log.levels.INFO)
            end
        )
        return 
    end

    if M.vcs == _G.WORKING_COPY_SVN then
        local svn = svn:new(config)
        svn:blame(filename, cwd, nil,
            function(data)
                vim.schedule(function()
                    local parsed_blames = porcelain_parser.parse_porcelain(data, _G.WORKING_COPY_SVN)
                    blame_view:open(parsed_blames)
                end)
            end, 
            function(err)
                vim.notify(err, vim.log.levels.INFO)
            end
        )
        return 
    end
end


---@return boolean | nil
M.is_open = function()
    return M.last_opened_view ~= nil and M.last_opened_view:is_open()
end

---@param setup_args Config | nil
M.setup = function(setup_args)

    local vcs, _ = check_vcs()
    if not vcs then 
        -- vim.notify("not under any vcs system", vim.log.levels.INFO)
        return 
    end

    ---@field vcs number identify it is under which version control system
    M.vcs = vcs

    -- vim.notify("vcs:"..vcs, vim.log.levels.INFO)

    config = vim.tbl_deep_extend("force", config, setup_args or {})

    local blame_view = config.views.default:new(config)

    vim.api.nvim_create_user_command("BlameToggle", function(args)
        config.ns_id = vim.api.nvim_create_namespace("blame_ns")

        if M.is_open() then
            M.last_opened_view:close(false)
            M.last_opened_view = nil
        else
            local arg = args.args == "" and "default" or args.args
            blame_view = config.views[arg]:new(config)
            open(blame_view)
            M.last_opened_view = blame_view
        end
    end, {
        nargs = "?",
        complete = function()
            local all_views = {}
            for k, _ in pairs(config.views) do
                if k ~= "default" then
                    table.insert(all_views, k)
                end
            end
            return all_views
        end,
    })
end

return M
