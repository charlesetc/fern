require 'init'
local dbg = require 'debugger'
local stringx = require 'pl.stringx'
local ns = vim.api.nvim_create_namespace('fern')

local function eval_lua_expression(s)
  local ok, result = pcall(loadstring("return " .. s))
  local output = dbg.pretty(result)
  if not ok then
    output = "error: " .. output
  end
  return output
end

local function read_list_item(s)
  if string.match(stringx.strip(s), "^%w") then
    return stringx.strip(s)
  end
  local ok, output = pcall(loadstring("return " .. s))
  if not ok then
    output = "error: " .. output
  end
  return output
end

local function evaluate()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local list_in_training = nil

  for i, line in ipairs(lines) do
    if stringx.startswith(line, "> ") then
      -- we've got a code block
      local luacode = string.sub(line, 2)
      vim.api.nvim_buf_set_extmark(
        0, ns, i - 1, 0,
        { virt_lines = { { { eval_lua_expression(luacode), "Comment" } } } }
      )
    elseif stringx.startswith(line, "---") and lines[i - 1] and string.match(lines[i - 1], "^%s*[%w_]+%s*$") then
      --- we've got a list
      list_in_training = {
        name = stringx.strip(lines[i - 1]),
        contents = {}
      }
    elseif string.sub(line, 0, 2) == "- " and list_in_training then
      -- we're in a list
      local luacode = string.sub(line, 2)
      local output = read_list_item(luacode)
      table.insert(list_in_training.contents, output)
    elseif list_in_training then
      _G[list_in_training.name] = list_in_training.contents
      list_in_training = nil
    end
  end
end

local group = vim.api.nvim_create_augroup("fern", {})


vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" },
  {
    group = group,
    pattern = { "*.fern" },
    callback = function()
      evaluate()
    end
  })

evaluate()
