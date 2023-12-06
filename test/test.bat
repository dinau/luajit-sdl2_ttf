@echo off
set LUA_PATH=;;..\?.lua
luajit test.lua
