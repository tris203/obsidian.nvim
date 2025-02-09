local snacks_picker = require "snacks.picker"
local snacks = require "snacks"


local Path = require "obsidian.path"
local abc = require "obsidian.abc"
local Picker = require "obsidian.pickers.picker"

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

---@class obsidian.pickers.SnacksPicker : obsidian.Picker
local SnacksPicker = abc.new_class({
    ---@diagnostic disable-next-line: unused-local
    __tostring = function(self)
        return "SnacksPicker()"
    end,
}, Picker)

SnacksPicker.find_files = function(self, opts)
    opts = opts and opts or {}

    ---@type obsidian.Path
    local dir = opts.dir and Path:new(opts.dir) or self.client.dir

    local result = snacks_picker.pick("files", {
        cwd = tostring(dir),
    })

    if result and opts.callback then
        local path = clean_path(result)
        opts.callback(tostring(dir / path))
    end
end

SnacksPicker.grep = function(self, opts)
    opts = opts and opts or {}

    ---@type obsidian.Path
    local dir = opts.dir and Path:new(opts.dir) or self.client.dir

    local result = snacks_picker.pick("grep", {
        cwd = tostring(dir),
    })

    if result and opts.callback then
        local path = clean_path(result)
        opts.callback(tostring(dir / path))
    end
end

SnacksPicker.pick = function(self, values, opts)

  self.calling_bufnr = vim.api.nvim_get_current_buf()

  local buf = opts.buf or vim.api.nvim_get_current_buf()

  opts = opts and opts or {}

  local entries = {}
  for _, value in ipairs(values) do
    if type(value) == "string" then
      table.insert(entries, { 
                text = value, 
                value = value, 
      })
    elseif value.valid ~= false then
      local name =  self:_make_display(value)
      table.insert(entries, { 
                text = name,
                buf = buf,
                filename = value.filename,
                value = value.value,
                pos = { value.lnum, value.col },
      })
    end
  end

  snacks_picker({
    tilte = opts.prompt_title,
    items = entries,
    layout = {
            preview = false
    },
    format = function(item, _)
      local ret = {}
      local a = snacks_picker.util.align
      ret[#ret + 1] = { a(item.text, 20) }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        if opts.callback then
            opts.callback(item.value)
        elseif item then
            vim.schedule(function()
                if item["buf"] then
                    vim.api.nvim_set_current_buf(item["buf"])
                end
                vim.api.nvim_win_set_cursor(0, {item["pos"][1], 0})
            end)
        end
      end
    end,
    -- sort = require("snacks.picker.sort").idx(),
  })
end

return SnacksPicker
