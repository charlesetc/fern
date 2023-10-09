-- pull in my global stdlib, such as the logger
dofile("/Users/charles/.lua/init.lua")

-- setup `require` to work with dependencies
function addpath(path)
    local dir = debug.getinfo(2, "S").source:sub(2):match("(.*/)")
    package.path = package.path .. ';' .. dir .. path .. '/?.lua;' .. dir .. path .. '/?/?.lua'
end

addpath('dependencies')

dbg = require 'debugger'
pp = dbg.pp
