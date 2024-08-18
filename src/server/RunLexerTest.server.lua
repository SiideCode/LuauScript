local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local lexerModule = require(ReplicatedStorage.Shared.LuauScript.AST.Lexer)

-------------------------------------------------------------------------------------------

local lexer = lexerModule.new()

lexer:setScript(testScript, "test_script.txt")

local toks = {}
local a = lexer:nextToken()
table.insert(toks, a)

local hhh = function()
				while (a.t ~= lexerModule.tokT.eof) and (a.t ~= nil) do
					a = lexer:nextToken()
					table.insert(toks, a)
					print(a, lexerModule.tokTMirror[a.t])
					print(toks)
				end
				if a.t == lexerModule.tokT.eof then
					print(a.t)
				end
			end

-- xpcall sometimes returns weird ass errors. i REALLY need the value return handling.
--xpcall(
	hhh()--,

	--[[function(lel:any)
		if type(lel) == "table" then
			print(table:unpack(lel))
		elseif lel ~= nil then
			print(lel)
		end
	end)]]

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