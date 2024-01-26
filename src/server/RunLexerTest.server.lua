local execStart = os.time()

local testScript = [[
package;

class Main
{
	var hey = "hiya\n\r\n\n\u{12345f}\u12ff\123\xff";
}
]]
--[[
// oval
/*
boval
*/
package src_al.cac;

import heya.iam.Bob;

class Greeting
{
	var aa = 0x32ba;
    var M:Int = 34;
    var H:Float = 34.5;
    var L:String = "elo";
    var regexp = ~/[A-Z]/i;

    H += 2;

    H >>= 3;

    H *= 2;

    H = H / 2;

	H /= 2;

    print(L);
}]]

local lexerModule = require(workspace.LuauScript.AST.Lexer)
local lexerErr = require(workspace.LuauScript.AST.LexerModules.LexerError)
local tokModule = require(workspace.LuauScript.AST.LexerModules.Token)

-------------------------------------------------------------------------------------------

lexerModule:setScript(testScript, "test_script.txt")

local toks = {}
local a = lexerModule:nextToken()
table.insert(toks, a)

-- don't ask me about the xpcall
xpcall(
	function()
		while a and a.type ~= tokModule.tokT.eof do
			a = lexerModule:nextToken()
			table.insert(toks, a)
		end
		if a.type == tokModule.tokT.eof then
			print(a.type)
		end
	end,

	function(lel:any)
		if type(lel) == "table" then
			print(table:unpack(lel))
		else
			print(lel)
		end
	end)

for i, k in ipairs(toks) do
	print(i, k, "[tokName] = " .. tokModule.tokTMirror[k["type"]])
end

-------------------------------------------------------------------------------------------

local execEnd = os.time()

print(string.format("executed in %dms (%d - %d)\n", execEnd - execStart, execEnd, execStart))

-- Thread (actor) creation (possibly??)
--[[
local aaa = script:Clone()
aaa.Parent = workspace.Threads
aaa.Name = "Thread1"
]]

-- new actor obj
--Instance.new("Actor")