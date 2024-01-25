local LexerError = {}
LexerError.__index = LexerError

local tok = require(workspace.LuauScript.AST.LexerModules.Token)

function LexerError:new(msg:string, lastToken:tok, fileRef:string?, tokStr:string?)
	local lexerrInstance = {}

	setmetatable(lexerrInstance, self)

	lexerrInstance.msg = msg
	lexerrInstance.lastToken = lastToken
	lexerrInstance.fileRef = fileRef
	lexerrInstance.tokStr = tokStr

	return lexerrInstance
end

return LexerError
