local snacks_picker = require "snacks.picker"
local snacks = require "snacks"


local Path = require "obsidian.path"
local abc = require "obsidian.abc"
local Picker = require "obsidian.pickers.picker"


function print_table(t, indent)
    indent = indent or 0
    local padding = string.rep("  ", indent)

    for key, value in pairs(t) do
        if type(value) == "table" then
            print(padding .. tostring(key) .. " = {")
            print_table(value, indent + 1)
            print(padding .. "}")
        else
            print(padding .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

function table_to_string(t, indent)
    if type(t) ~= "table" then return tostring(t) end

    indent = indent or 0
    local padding = string.rep("  ", indent)
    local parts = {}

    for k, v in pairs(t) do
        local key = type(k) == "number" and "[" .. k .. "]" or k
        local value
        if type(v) == "table" then
            value = "{\n" .. table_to_string(v, indent + 1) .. padding .. "}"
        elseif type(v) == "string" then
            value = string.format("%q", v)
        else
            value = tostring(v)
        end
        parts[#parts + 1] = padding .. key .. " = " .. value
    end

    return table.concat(parts, ",\n") .. "\n"
end

---@param entry string
---@return string
local function clean_path(entry)
    if type(entry) == "string" then
        local path_end = assert(string.find(entry, ":", 1, true))
        return string.sub(entry, 1, path_end - 1)
    end
    vim.notify("entry: " .. table.concat(vim.tbl_keys(entry), ", "))
    return ""
end

local function map_actions(action)
    if type(action) == "table" then
        opts = { win = { input = { keys = {} } }, actions = {} };
        for k, v in pairs(action) do
            local name = string.gsub(v.desc, " ", "_")
            opts.win.input.keys = {
                [k] = { name, mode = { "n", "i" }, desc = v.desc }
            }
            opts.actions[name] = function(picker, item)
                vim.notify("action item: " .. table_to_string(item))
                v.callback({args: item.text})
            end
        end
        return opts
    end
    return {}
end

---@class obsidian.pickers.SnacksPicker : obsidian.Picker
local SnacksPicker = abc.new_class({
    ---@diagnostic disable-next-line: unused-local
    __tostring = function(self)
        return "SnacksPicker()"
    end,
}, Picker)

SnacksPicker.find_files = function(self, opts)
    opts = opts or {}

    ---@type obsidian.Path
    local dir = opts.dir and Path:new(opts.dir) or self.client.dir

    local pick_opts = vim.tbl_extend("force", map or {}, {
        source = "files",
        title = opts.prompt_title,
        cwd = opts.dir.filename,
        confirm = function(picker, item, action)
            picker:close()
            if item then
                if opts.callback then
                    opts.callback(item._path)
                else
                    snacks_picker.actions.jump(picker, item, action)
                end
            end
        end,
    })
    snacks_picker.pick(pick_opts)
end

SnacksPicker.grep = function(self, opts, action)
    opts = opts or {}

    ---@type obsidian.Path
    local dir = opts.dir and Path:new(opts.dir) or self.client.dir

    local pick_opts = vim.tbl_extend("force", map or {}, {
        source = "grep",
        title = opts.prompt_title,
        cwd = opts.dir.filename,
        confirm = function(picker, item, action)
            picker:close()
            if item then
                if opts.callback then
                    opts.callback(item._path)
                else
                    snacks_picker.actions.jump(picker, item, action)
                end
            end
        end,
    })
    snacks_picker.pick(pick_opts)
end

SnacksPicker.pick = function(self, values, opts)
    self.calling_bufnr = vim.api.nvim_get_current_buf()

    opts = opts or {}

    local buf = opts.buf or vim.api.nvim_get_current_buf()

    -- local map = vim.tbl_deep_extend("force", {},
    --     map_actions(opts.selection_mappings),
    --     map_actions(opts.query_mappings))

    local entries = {}
    for _, value in ipairs(values) do
        if type(value) == "string" then
            table.insert(entries, {
                text = value,
                value = value,
            })
        elseif value.valid ~= false then
            local name = self:_make_display(value)
            table.insert(entries, {
                text = name,
                buf = buf,
                filename = value.filename,
                value = value.value,
                pos = { value.lnum, value.col },
            })
        end
    end

    local pick_opts = vim.tbl_extend("force", map or {}, {
        tilte = opts.prompt_title,
        items = entries,
        layout = {
            preview = false
        },
        format = "text",
        confirm = function(picker, item)
            picker:close()
            if item and opts.callback then
                if type(item) == "string" then
                    opts.callback(item)
                else
                    opts.callback(item.value)
                end
            end
        end,
    })

    local entry = snacks_picker.pick(pick_opts)
end

return SnacksPicker
