--!strict
local Lexer = {}

local tokenMod = require(workspace.LuauScript.AST.LexerModules.Token)
local posMod = require(workspace.LuauScript.AST.LexerModules.Pos)
local errorMod = require(workspace.LuauScript.AST.LexerModules.LexerError)

--current position in string
local curposreal = 1
--current position in line
local curpos = 1
--current line
local curline = 1
--a list of symbols
local buf = {}
--name of the file
local fileref = ""
--current state of the lexer
local lexerState = 1

--a variable that contains the state that should be next after the current state
local returnToState = 1

--List of reserved keywords
local resKeywords =
{
	"package",
	"import",
	"using",
	"class",
	"interface",
	"enum",
	"abstract",
	"typedef",
	"extends",
	"implements",
	"static",
	"global",
	"public",
	"private",
	"override",
	"dynamic",
	"inline",
	"final",
	"operator",
	"overload",
	"function",
	"var",
	"null",
	"true",
	"false",
	"this",
	"if",
	"while",
	"do",
	"for",
	"break",
	"continue",
	"return",
	"switch",
	"case",
	"default",
	"throw",
	"try",
	"catch",
	"untyped",
	"new",
	"in",
	"cast"
}

--List of all lexer states for convinience
local lexerStates =
{
	--standard state, tries to find normal tokens
	seekTokens = 1,
	--reads a two quoted string, differentiates between letters, escapes, newlines and etc.
	readStringTwoQuotes = 2,
	--like a readStringTwoQuotes, but with $ and ${} interpolation support. btw $$ is an escape for an actual dollar lol
	readStringOneQuote = 3,
	--reads a regular expression, returning it's different parts as different tokens
	readRegexp = 4,
	--reads a single line comment, includes markdown and other stuff to support docs
	readComment = 5,
	--reads a multiline comment, includes markdown and other stuff to support docs
	readMultiComment = 6,
	--just returns a newline if there's one, and that's it
	returnNewlineTok = 7,
	--reads and returns a string escape
	readStringEscape = 8,
	--reads and returns a double quote of a string
	readStringQuoteDouble = 9
}

--[[
	FIXME: Fix all escapes outputting in a COMPLETELY wrong way:

	[20] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 69,
        ["value"] = """
    },
    [21] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 71,
        ["value"] = ""
    },
    [22] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 72,
        ["value"] = "\"
    },
    [23] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 71,
        ["value"] = "n"
    },
    [24] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 72,
        ["value"] = "\"
    },
    [25] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 71,
        ["value"] = "n"
    },
    [26] =  ▼  {
		["position"] =  ▶ {...},
		["type"] = 72,
		["value"] = "\"
    },
    [27] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 71,
        ["value"] = "r"
    },
    [28] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 72,
        ["value"] = "\r"
    },
    [29] =  ▼  {
        ["position"] =  ▶ {...},
        ["type"] = 71,
        ["value"] = ""
    }
]]

local function stringEscapeRead(tokPos:posMod)
	lexerState = returnToState
	local tokContent = ""
	print(buf[curposreal])

	while buf[curposreal] ~= " " and buf[curposreal] ~= "\"" and (buf[curposreal] ~= "\n" or buf[curposreal] ~= "\r") and buf[curposreal+1] ~= "\\" do
		print(buf[curposreal])
		tokContent ..= buf[curposreal]
		curpos += 1
		curposreal += 1
		tokPos.endPos += 1
		if curposreal == #buf then
			error(errorMod:new("Invalid string escape.", tokenMod:new(tokenMod.tokT.strEscape, tokContent, tokPos), fileref), 1)
		end
	end

	if buf[curposreal] == "\\" then
		lexerState = lexerStates.readStringEscape
	end

	print(buf[curposreal])
	return tokenMod:new(tokenMod.tokT.strEscape, tokContent, tokPos)
end

--[[
	Reads a double quoted string, goes to state returnNewlineTok if it finds a \n or \r, if there isn't, it just returns to state seekTokens.
]]
local function doubleQuoteStringRead(tokPos:posMod)
	local tokContent = ""
	print(buf[curposreal])

	while buf[curposreal] ~= "\"" and (buf[curposreal] ~= "\n" or buf[curposreal] ~= "\r") and buf[curposreal] ~= "\\" do
		print(buf[curposreal])
		tokContent ..= buf[curposreal]
		curpos += 1
		curposreal += 1
		tokPos.endPos += 1
		if curposreal == #buf then
			error(errorMod:new("Unclosed string.", tokenMod:new(tokenMod.tokT.strLetters, tokContent, tokPos), fileref), 1)
		end
	end

	if buf[curposreal] == "\n" or buf[curposreal] == "\r" then
		lexerState = lexerStates.returnNewlineTok
		returnToState = lexerStates.readStringTwoQuotes
	elseif buf[curposreal] == "\\" and tokContent == nil then
		return stringEscapeRead(tokPos)
	elseif buf[curposreal] == "\\" then
		lexerState = lexerStates.readStringEscape
		returnToState = lexerStates.readStringTwoQuotes
	elseif buf[curposreal] == "\"" then
		lexerState = lexerStates.readStringQuoteDouble
		returnToState = lexerStates.seekTokens
	else
		lexerState = lexerStates.seekTokens
		returnToState = lexerStates.seekTokens
	end

	print("state:", lexerState, "state to return to:", returnToState)

	print(buf[curposreal])
	return tokenMod:new(tokenMod.tokT.strLetters, tokContent, tokPos)
end

--[[
	A function that checks if there's a newline.
	It's here for readability, and it makes the code reusable
]]
local function doNewlineCheck(tokPos:posMod)
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	if buf[curposreal] == "\n" or buf[curposreal] == "\r" then
		tokPos.startPos = curpos
		if buf[curposreal] == "\r" and buf[curposreal+1] == "\n" then
			tokPos.endPos = curpos + 1
			curline += 1
			curpos = 2
			print(buf[curposreal])
			curposreal += 2
			return tokenMod:new(tokenMod.tokT.newlineReturn, "\r\n", tokPos)
		else
			local whar = "\n"
			if buf[curposreal-1] == "\r" then
				whar = "\r"
			end

			tokPos.endPos = curpos
			curline += 1
			curpos = 1
			print(buf[curposreal])
			curposreal += 1

			return tokenMod:new(tokenMod.tokT.newline, whar, tokPos)
		end
	end
	return nil
end

local function readStringQuoteDouble(tokPos:posMod)
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	tokPos.startPos = curpos
	tokPos.endPos = curpos
	curpos += 1
	curposreal += 1

	return tokenMod:new(tokenMod.tokT.str, "\"", tokPos)
end

--[[
	This sets the current script for the lexer or something idk
]]
function Lexer:setScript(script:string, filename:string?)
	buf = script:split("")
	fileref = filename
end

--[[
	Resets the position and state of the lexer.
	Might be useful if you want to lex the script from the beginning.
]]
function Lexer:resetState()
	curposreal = 1
	curpos = 1
	curline = 1
	lexerState = 1
end

function Lexer:nextToken()
	local tokPos = posMod:new(0, 0, 0)

	local function proceed(amount:number?)
		if amount then
			tokPos.endPos += (amount - 1)
			curposreal += amount
			curpos += amount
		else
			curposreal += 1
			curpos += 1
		end
	end

	print("finding token, current state is", lexerState)

	tokPos.line = curline

	--[[
		if we're not seeking normal tokens, then we're seeking something else.
		this handles the actions if the state isn't seekTokens
	]]
	if lexerState ~= lexerStates.seekTokens then
		if lexerState == lexerStates.readStringTwoQuotes then
			return doubleQuoteStringRead(tokPos)
		elseif lexerState == lexerStates.readStringOneQuote then
			return error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.readStringQuoteDouble then
			return readStringQuoteDouble(tokPos)
		elseif lexerState == lexerStates.readStringEscape then
			return stringEscapeRead(tokPos)
		elseif lexerState == lexerStates.readRegexp then
			return error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.readComment then
			return error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.readMultiComment then
			return error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.returnNewlineTok then
			return doNewlineCheck(tokPos)
		end
	end

	if #buf == 0 or curposreal > #buf then
		return tokenMod:new(tokenMod.tokT.eof, "<EOF>", tokPos)
	end

	if buf[curposreal] == " " or buf[curposreal] == "\t" then
		local spacesntabs = ""
		tokPos.startPos = curpos
		while buf[curposreal] == " " or buf[curposreal] == "\t" do
			if buf[curposreal] == " " or buf[curposreal] == "\t" then
				spacesntabs ..= buf[curposreal]
				proceed()
				print(buf[curposreal])
			end
		end
		tokPos.endPos = curpos
		return tokenMod:new(tokenMod.tokT.tab, spacesntabs, tokPos)
	end

	--check if there are newlines, if there are, then we return
	local apossiblenewline = doNewlineCheck(tokPos)
	if apossiblenewline ~= nil then
		return apossiblenewline
	end

	--we iterate through keywords... yeah... and if there's no match we assume it's a class/function/variable/module/whatever
	if buf[curposreal]:find("[_%a]") then
		local somethingStr = ""
		tokPos.startPos = curpos

		while buf[curposreal]:find("[_%a%d]") do
			if buf[curposreal]:find("[_%a%d]") then
				somethingStr ..= buf[curposreal]
				proceed()
				print(somethingStr)
				print(buf[curposreal])
			end
		end

		tokPos.endPos = curpos

		for i in ipairs(resKeywords) do
			if somethingStr == resKeywords[i] then
				local aa = "kv" .. resKeywords[i]:sub(1, 1):upper() .. resKeywords[i]:sub(2)
				return tokenMod:new(tokenMod.tokT[aa], resKeywords[i], tokPos)
			end
		end

		if somethingStr:sub(1):find("[_%l%u]") then
			local curchar = ""
			local strposreal = 0
			local strpos = 0
			local beef = somethingStr:split("")

			strpos += 2
			strposreal += 2

			while beef[1] == "_" do
				strpos += 1
				strposreal += 1
			end

			if beef[strposreal]:find("[%l%d]") then
				while beef[strposreal] ~= "" and beef[strposreal] ~= nil and beef[strposreal] do
					strpos += 1
					strposreal += 1
					print(curposreal, curpos, curline)
				end
				return tokenMod:new(tokenMod.tokT.ident, somethingStr, tokPos)
			elseif curchar:find("%u") then
				while curchar ~= "" and curchar ~= nil and curchar do
					curchar = beef[strposreal]
					strpos += 1
					strposreal += 1
					print(curposreal, curpos, curline)
				end
				return tokenMod:new(tokenMod.tokT.identT, somethingStr, tokPos)
			end
		end
	--numbahs
	elseif buf[curposreal]:find("%d") then
		local someth = ""
		local isfloat = false
		local ishex = false
		local hasexponent = false
		tokPos.startPos = curpos
		while buf[curposreal]:find("[%.%dx%xe]") do
			print(someth)
			print(buf[curposreal])
			if buf[curposreal]:find("%d") or (ishex and buf[curposreal]:find("%x"))then
				someth ..= buf[curposreal]
				proceed()
			elseif buf[curposreal]:find("%.") and isfloat == false then
				someth ..= buf[curposreal]
				proceed()
				isfloat = true
			elseif buf[curposreal] == "x" and ishex == false then
				someth ..= buf[curposreal]
				proceed()
				ishex = true
			elseif buf[curposreal] == "e" and hasexponent == false then
				someth ..= buf[curposreal]
				proceed()
				hasexponent = true
			end
		end

		tokPos.endPos = curpos

		if isfloat then
			if hasexponent then
				if someth:sub(1,1) == "." then
					return tokenMod:new(tokenMod.tokT.peFloat, tonumber(someth), tokPos)
				else
					return tokenMod:new(tokenMod.tokT.eFloat, tonumber(someth), tokPos)
				end
			elseif someth:sub(1,1) == "." then
				return tokenMod:new(tokenMod.tokT.pFloat, tonumber(someth), tokPos)
			else
				return tokenMod:new(tokenMod.tokT.float, tonumber(someth), tokPos)
			end
		elseif ishex then
			return tokenMod:new(tokenMod.tokT.hex, tonumber(someth), tokPos)
		else
			return tokenMod:new(tokenMod.tokT.int, tonumber(someth), tokPos)
		end
	--we do some op checks
	elseif buf[curposreal] == ";" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.semicolon, ";", tokPos)
	elseif buf[curposreal] == ":" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.semicolon, ":", tokPos)
	elseif buf[curposreal] == "." then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "." and buf[curposreal+2] == "." then
			proceed(3)
			tokPos.endPos += 2
			return tokenMod:new(tokenMod.tokT.interval, "...", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.dot, ".", tokPos)
		end
	elseif buf[curposreal] == "," then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.comma, ",", tokPos)
	elseif buf[curposreal] == "{" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.cuBrakOpen, "{", tokPos)
	elseif buf[curposreal] == "}" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.cuBrakClose, "}", tokPos)
	elseif buf[curposreal] == "(" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.brakOpen, "(", tokPos)
	elseif buf[curposreal] == ")" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.brakClose, ")", tokPos)
	elseif buf[curposreal] == "[" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.sqBrakOpen, "[", tokPos)
	elseif buf[curposreal] == "]" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return tokenMod:new(tokenMod.tokT.sqBrakClose, "]", tokPos)
	elseif buf[curposreal] == "\"" then
		--[[
			i was so happy when i made this work
			yippieeeeeeeeeeeeeeeeee
			-sidecode
		]]
		lexerState = lexerStates.readStringTwoQuotes
		returnToState = lexerStates.readStringTwoQuotes
		return readStringQuoteDouble(tokPos)
	elseif buf[curposreal] == "'" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		local maaan = buf[curposreal]
		proceed()
		while buf[curposreal] ~= "'" do
			maaan ..= buf[curposreal]
			proceed()
			tokPos.endPos += 1
			if curposreal == #buf then
				error(errorMod:new("Unclosed string.", tokenMod:new(tokenMod.tokT.fStr, maaan, tokPos), fileref), 1)
			end
		end
		print(buf[curposreal])
		return tokenMod:new(tokenMod.tokT.fStr, maaan, tokPos)
	elseif buf[curposreal] == "+" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.addAssign, "+=", tokPos)
		elseif buf[curposreal+1] == "+" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.unaryPlus, "++", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.addOp, "+", tokPos)
		end
	elseif buf[curposreal] == "-" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.subAssign, "-=", tokPos)
		elseif buf[curposreal+1] == "-" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.unaryMinus, "--", tokPos)
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.arrowF, "->", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.subOp, "-", tokPos)
		end
	elseif buf[curposreal] == "*" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.multAssign, "*=", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.multOp, "*", tokPos)
		end
	elseif buf[curposreal] == "/" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.divAssign, "/=", tokPos)
		elseif buf[curposreal+1] == "/" then
			proceed(2)
			local maythegodhelpme = "//"
			while buf[curposreal] ~= "\r" or buf[curposreal] ~= "\n" do
				if buf[curposreal] == "\r" or buf[curposreal] == "\n" then
					maythegodhelpme ..= buf[curposreal]
					proceed()
					curline = 1
					return tokenMod:new(tokenMod.tokT.comment, maythegodhelpme, tokPos)
				else
					maythegodhelpme ..= buf[curposreal]
					proceed()
					print(buf[curposreal])
				end
			end
			return tokenMod:new(tokenMod.tokT.comment, maythegodhelpme, tokPos)
		elseif buf[curposreal+1] == "*" then
			local maythegodhelpme = buf[curposreal] .. buf[curposreal+1]
			proceed(2)
			while true do
				if curposreal > #buf then
					error(errorMod:new("Unclosed multiline comment.", tokenMod:new(tokenMod.tokT.multiCom, maythegodhelpme, tokPos), fileref), 1)
				elseif buf[curposreal] == "*" and buf[curposreal+1] == "/" then
					print(maythegodhelpme)
					maythegodhelpme ..= buf[curposreal] 
					maythegodhelpme ..= buf[curposreal+1]
					print(maythegodhelpme)
					proceed(2)
					return tokenMod:new(tokenMod.tokT.multiCom, maythegodhelpme, tokPos)
				else
					maythegodhelpme ..= buf[curposreal]
					proceed()
					tokPos.endPos += 1
				end
			end
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.divOp, "/", tokPos)
		end
	elseif buf[curposreal] == "%" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.modAssign, "%=", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.mod, "%", tokPos)
		end
	elseif buf[curposreal] == ">" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.moreOrEqual, ">=", tokPos)
		elseif buf[curposreal+1] == ">" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return tokenMod:new(tokenMod.tokT.bitShiftRAssign, ">>=", tokPos)
			elseif buf[curposreal+2] == ">" then
				if buf[curposreal+3] == "=" then
					proceed(4)
					tokenMod:new(tokenMod.tokT.uBitShiftRAssign, ">>>=", tokPos)
				else
					proceed(3)
					return tokenMod:new(tokenMod.tokT.uBitShiftR, ">>>", tokPos)
				end
			else
				proceed(2)
				return tokenMod:new(tokenMod.tokT.bitShiftR, ">>", tokPos)
			end
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.moreOp, ">", tokPos)
		end
	elseif buf[curposreal] == "<" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.lessOrEqual, "<=", tokPos)
		elseif buf[curposreal+1] == "<" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return tokenMod:new(tokenMod.tokT.bitShiftLAssign, "<<=", tokPos)
			else
				proceed(2)
				return tokenMod:new(tokenMod.tokT.bitShiftL, "<<", tokPos)
			end
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.lessOp, "<", tokPos)
		end
	elseif buf[curposreal] == "|" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "|" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return tokenMod:new(tokenMod.tokT.orAssign, "||=", tokPos)
			else
				proceed(2)
				return tokenMod:new(tokenMod.tokT.orOp, "||", tokPos)
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.bitOrAssign, "|=", tokPos)	
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.bitOr, "|", tokPos)
		end
	elseif buf[curposreal] == "&" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "&" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return tokenMod:new(tokenMod.tokT.andAssign, "&&=", tokPos)
			else
				proceed(2)
				return tokenMod:new(tokenMod.tokT.andOp, "&&", tokPos)
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.bitAndAssign, "&=", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.bitAnd, "&", tokPos)
		end
	elseif buf[curposreal] == "?" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "?" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return tokenMod:new(tokenMod.tokT.nullCoalAssign, "??=", tokPos)
			else
				proceed(2)
				return tokenMod:new(tokenMod.tokT.nullCoal, "??", tokPos)
			end
		elseif buf[curposreal+1] == "." then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.qmarkDot, "?.", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.questionOp, "?", tokPos)
		end
	elseif buf[curposreal] == "^" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.bitXorAssign, "^=", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.bitXor, "^", tokPos)
		end
	elseif buf[curposreal] == "=" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.compare, "==", tokPos)
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return tokenMod:new(tokenMod.tokT.arrowM, "=>", tokPos)
		else
			proceed()
			return tokenMod:new(tokenMod.tokT.assignOp, "=", tokPos)
		end
	elseif buf[curposreal] == "~" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal + 1] == "/" then
			proceed(2)
			local aaal = "~/"
			print(buf[curposreal])
			while buf[curposreal] ~= "/" and buf[curposreal]:find("[%a%d\\r\\n\\t\r\n%$%.%*%+%-%^%?%[%]%(%)|{}]") do
				if curposreal >= #buf then
					error(errorMod:new("Unclosed regexp.", tokenMod:new(tokenMod.tokT.regexp, aaal, tokPos), fileref), 1)
				end
				if buf[curposreal] ~= "/" and buf[curposreal]:find("[%a%d\\r\\n\\t%$%.%*%+%-%^%?%[%]%(%)|{}]") then
					aaal ..= buf[curposreal]
					proceed()
					print(aaal)
					print(buf[curposreal])
				elseif buf[curposreal] == "\r" or buf[curposreal] == "\n" then
					error(errorMod:new("Unclosed regexp.", tokenMod:new(tokenMod.tokT.regexp, aaal, tokPos), fileref), 1)
				end
			end

			if curposreal >= #buf then
				error(errorMod:new("Unclosed regexp.", tokenMod:new(tokenMod.tokT.regexp, aaal, tokPos), fileref), 1)
			end

			if buf[curposreal] == "/" then
				aaal ..= buf[curposreal]
				proceed()
				print(aaal)
				print(buf[curposreal])
				if buf[curposreal] == "i" or buf[curposreal] == "g" or buf[curposreal] == "m" or buf[curposreal] == "s" or buf[curposreal] == "u" then
					aaal ..= buf[curposreal]
					proceed()
					print(aaal)
					print(buf[curposreal])
				end
				return tokenMod:new(tokenMod.tokT.regexp, aaal, tokPos)
			else
				print("WHAT")
				return nil
			end
		else
			return tokenMod:new(tokenMod.tokT.bitNot, "~", tokPos)
		end
	end
	error(errorMod:new("Unknown symbol.", tokenMod:new(0, buf[curposreal], tokPos), fileref), 1)
end

return Lexer