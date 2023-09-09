-- pull in my global stdlib, such as the logger
dofile("/Users/charles/.lua/init.lua")

-- setup `require` to work with dependencies
function addpath(path)
  package.path = package.path .. ';./' .. path .. '/?.lua;./' .. path .. '/?/?.lua'
end

addpath('dependencies')

dbg = require 'debugger'
pp = dbg.pp
