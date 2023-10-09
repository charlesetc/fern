dofile('/Users/charles/code/fern/init.lua')
local dbg = require 'debugger'
local stringx = require 'pl.stringx'
local ns = vim.api.nvim_create_namespace('fern')

local function eval_lua_expression(s)
  local expr, error = loadstring("return " .. s)
  if not expr then
    return "error: " .. error
  end

  local ok, result = pcall(expr)


  if vim.tbl_islist(result) then
    local lines = {}
    for _, item in ipairs(result) do
      table.insert(lines, "- " .. vim.inspect(item))
    end
    return table.concat(lines, "\n")
  end


  local output = vim.inspect(result)
  if not ok then
    return "error: " .. output
  end
  return output
end

local function read_list_item(s)
  local s = stringx.strip(s)
  if string.match(s, "^%a") then
    if s ~= "true" and s ~= "false" then
      return true, stringx.strip(s)
    end
  end


  local expr, error = loadstring("return " .. s)
  if expr then
    return pcall(expr)
  else
    return false, error
  end
end

local function annotate(lineno, str)
  local virtlines = {}
  local i = 0
  for line in str:gmatch("[^\r\n]+") do
    L.log('#########', i, line)
    i = i + 1
    table.insert(virtlines, { { line, "Comment" } })
  end
  vim.api.nvim_buf_set_extmark(
    0, ns, lineno - 1, 0,
    { virt_lines = virtlines }
  )
end

local function evaluate()
  L.log("--- fern eval ---")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local list_in_training = nil

  for i, line in ipairs(lines) do
    if stringx.startswith(line, "> ") then
      -- we've got a code block
      local luacode = string.sub(line, 2)
      annotate(i, eval_lua_expression(luacode))
    elseif stringx.startswith(line, "---") and lines[i - 1] and string.match(lines[i - 1], "^%s*[%w_]+%s*$") then
      --- we've got a list
      list_in_training = {
        name = stringx.strip(lines[i - 1]),
        contents = {}
      }
    elseif string.sub(line, 0, 2) == "- " and list_in_training then
      -- we're in a list
      local luacode = string.sub(line, 2)
      local ok, output = read_list_item(luacode)
      L.log(ok, vim.inspect(output))
      if ok then
        table.insert(list_in_training.contents, output)
      else
        annotate(i, "error: " .. output)
      end
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
