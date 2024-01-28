--!strict
local Lexer = {}
Lexer.__index = Lexer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Packages.tableutil)

type Position = {
	startPos:number,
	endPos:number,
	line:number,
	fileRef:string?
}

type Token = {
	type:number,
	value:string?,
	position:Position
}

type LexerError = {
	msg:string,
	lastToken:Token,
	fileRef:string?,
	tokStr:string?
}

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

Lexer.tokT =
{
	unknown = 0,						-- 0: unknown symbol
	eof = 1,							-- 1: EOF
	tab = 2,							-- 2: tabulation
	newlineReturn = 3,					-- 3: carriage return and new line
	newline = 4,						-- 4: new line or carriage return
	hex = 5,							-- 5: hexadecimal number
	int = 6,							-- 6: integer
	float = 7,							-- 7: floating point
	pFloat = 8,							-- 8: floating point no whole part
	peFloat = 9,						-- 9: floating point exponent no whole part
	eFloat = 10,						-- 10: floating point exponent
	--TODO: understand why the hell it exists in haxe
	intInt = 11,						-- 11: integer interval
	comment = 12,						-- 12: one line comment
	unaryPlus = 13,						-- 13: unary +1
	unaryMinus = 14,					-- 14: unary -1
	bitNot = 15,						-- 15: bitwise not (every 1 = 0, every 0 = 1).
	modAssign = 16,						-- 16: module + assign
	bitAndAssign = 17,					-- 17: bitwise AND + assign
	bitOrAssign = 18,					-- 18: bitwise OR + assign
	bitXorAssign = 19,					-- 19: bitwise XOR + assign
	addAssign = 20,						-- 20: add + assign
	subAssign = 21,						-- 21: substract + assign
	multAssign = 22,					-- 22: multiply + assign
	divAssign = 23,						-- 23: divide + assign
	bitShiftLAssign = 24,				-- 24: bit shift left + assign
	bitShiftRAssign = 25,				-- 25: bit shift right + assign
	uBitShiftRAssign = 26,				-- 26: unsigned bit shift left
	orAssign = 27,						-- 27: or + assign
	andAssign = 28,						-- 28: and + assign
	nullCoalAssign = 29,				-- 29: null coalescing + assign (https://www.tutorialspoint.com/What-is-a-null-coalescing-operator-in-JavaScript)
	compare = 30,						-- 30: compare
	notEqual = 31,						-- 31: not equals
	lessOrEqual = 32,					-- 32: less/equals
	moreOrEqual = 33,					-- 33: more/equals
	andOp = 34,							-- 34: and
	orOp = 35,							-- 35: or
	bitShiftL = 36,						-- 36: bit shift left
	bitShiftR = 37,						-- 37: bit shift right
	uBitShiftR = 38,					-- 38: unsigned bit shift right
	arrowF = 39,						-- 39: arrow (https://haxe.org/manual/expression-arrow-function.html) (https://haxe.org/manual/lf-function-bindings.html)
	interval = 40,						-- 40: interval from...to
	arrowM = 41,						-- 41: arrow (for map and array loops with indexes)
	notOp = 42,							-- 42: not
	lessOp = 43,						-- 43: less
	moreOp = 44,						-- 44: more
	semicolon = 45,						-- 45: semicolon
	colon = 46,							-- 46: colon
	comma = 47,							-- 47: comma
	dot = 48,							-- 48: dot
	qmarkDot = 49,						-- 49: question mark + dot (https://bobbyhadz.com/blog/typescript-question-mark-dot)
	mod = 50,							-- 50: module
	bitAnd = 51,						-- 51: bitwise and
	bitOr = 52,							-- 52: bitwise or
	bitXor = 53,						-- 53: bitwise XOR
	addOp = 54,							-- 54: add
	multOp = 55,						-- 55: multiply
	divOp = 56,							-- 56: divide
	subOp = 57,							-- 57: substract
	assignOp = 58,						-- 58: assign
	sqBrakOpen = 59,					-- 59: open square brackets
	sqBrakClose = 60,					-- 60: close square brackets
	cuBrakOpen = 61,					-- 61: open curly brackets
	cuBrakClose = 62,					-- 62: close curly brackets
	brakOpen = 63,						-- 63: open brackets
	brakClose = 64,						-- 64: close brackets
	nullCoal = 65,						-- 65: null coalescing (https://www.tutorialspoint.com/What-is-a-null-coalescing-operator-in-JavaScript)
	questionOp = 66,					-- 66: question mark
	atMacro = 67,						-- 67: at (macros)
	multiCom = 68,						-- 68: begin multiline comment
	str = 69,							-- 69: start/begin string ("")
	fStr = 70,							-- 70: start/begin formatted string ('')
	strLetters = 71,					-- 71: string letters
	strEscape = 72,						-- 72: escapes in strings
	fStrDollarContent = 73,				-- 73: everything after $, between ${ and }. $$ just adds a $ to fStr.
	--(haxe regexp rules: https://haxe.org/manual/std-regex.html)
	regexp = 74,						-- 74: start/end of the regexp (https://haxe.org/manual/std-regex.html)
	sharp = 75,							-- 75: i forgot why it exists.
	dollar = 76,						-- 76: dollar for something
	--keywords
	kvPackage = 77,						-- 77: module path declaration keyword
	kvImport = 78,						-- 78: module import keyword
	kvUsing = 79,						-- 79: using (https://haxe.org/manual/lf-static-extension.html)
	kvClass = 80,						-- 80: class declaration keyword
	kvInterface = 81,					-- 81: interface keyword
	kvEnum = 82,						-- 82: enum keyword
	kvAbstract = 83,					-- 83: abstract type/class/enum modifier keyword (https://haxe.org/manual/types-abstract.html) (https://haxe.org/manual/types-abstract-class.html)
	kvTypedef = 84,						-- 84: type/struct declaration keyword
	kvExtends = 85,						-- 85: class extension keyword
	kvImplements = 86,					-- 86: interface implementation keyword
	--TODO: decide if it's needed later
	--kvExtern = 87,					-- 87: extern keyword (https://haxe.org/manual/lf-externs.html)
	kvStatic = 87,						-- 87: static modifier (doesn't exist in lua)
	kvGlobal = 88,						-- 88: global modifier, potentially incompatible with static and public keywords
	kvPublic = 89,						-- 89: public modifier
	kvPrivate = 90,						-- 90: private modifier
	kvOverride = 91,					-- 91: override modifiers, overloads the function
	kvDynamic = 92,						-- 92: dynamic access to a variable i guess
	kvInline = 93,						-- 93: inline keyword
	--TODO: actually uncomment this when i'm not lazy
	--kvMacro = 94,						-- 94: haxe macro modifier.
	kvFinal = 94,						-- 94: constant (might get unused, cause it can only be emulated)
	kvOperator = 95,					-- 95: operator function modifier keyword
	kvOverload = 96,					-- 96: overloading keyword
	kvFunction = 97,					-- 97: function keyword
	kvVar = 98,							-- 98: variable keyword
	kvNull = 99,						-- 99: null
	kvTrue = 100,						-- 100: true
	kvFalse = 101,						-- 101: false
	kvThis = 102,						-- 102: basically self in lua
	kvIf = 103,							-- 103: if
	kvElse = 104,						-- 104: else
	kvWhile = 105,						-- 105: while
	kvDo = 106,							-- 106: do (i forgot why it's here)
	kvFor = 107,						-- 107: for (for-cycle lol)
	kvBreak = 108,						-- 108: break
	kvContinue = 109,					-- 109: continue
	kvReturn = 110,						-- 110: return
	kvSwitch = 111,						-- 111: switch
	kvCase = 112,						-- 112: case
	kvDefault = 113,					-- 113: default cours of action for switch case/variable access modifier
	kvThrow = 114,						-- 114: throw an error
	kvTry = 115,						-- 115: try
	kvCatch = 116,						-- 116: catch
	kvUntyped = 117,					-- 117: suppress typechecker for the line
	kvNew = 118,						-- 118: new() constructor
	kvIn = 119,							-- 119: in
	kvCast = 120,						-- 120: read https://haxe.org/manual/expression-cast-unsafe.html and https://haxe.org/manual/expression-cast-safe.html
	ident = 121,						-- 121: packages and variables.
	identT = 122						-- 122: classes and types
}

Lexer.tokTMirror = TableUtil.DictUtil.mirrorDictionary(Lexer.tokT)

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
	"macro",
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

local function readStringQuoteDouble(tokPos:Position)
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	tokPos.startPos = curpos
	tokPos.endPos = curpos
	curpos += 1
	curposreal += 1

	return {Lexer.tokT.str, "\"", tokPos}
end

--TODO: revamp this someday, i don't like it.
local function stringEscapeRead(tokPos:Position)
	lexerState = returnToState
	local tokContent = ""

	tokPos.startPos = curpos
	tokPos.endPos = curpos

	if buf[curposreal] == "\\" then
		tokContent ..= "\\"
		curposreal += 1
		curpos += 1
	else
		error("A STRING ESCAPE ERROR OCCURED! PLEASE, SEND THIS TO THE DEVELOPER!")
	end

	if buf[curposreal] == "r" or buf[curposreal] == "n" or buf[curposreal] == "t" 
	or buf[curposreal] == "\"" or buf[curposreal] == "'" or buf[curposreal] == "\\" then
		tokContent ..= buf[curposreal]
		curposreal += 1
		curpos += 1
		tokPos.endPos += 1
	elseif string.find(buf[curposreal], "%d") then
		tokContent ..= buf[curposreal]

		local poo = 1
		for i = 1, 2, 1 do
			if string.find(buf[curposreal+poo], "%d") then
				tokContent ..= buf[curposreal+poo]
				poo += 1
			else
				break;
			end
		end

		curposreal += poo
		curpos += poo
		tokPos.endPos += poo - 1
	elseif buf[curposreal] == "x" then
		tokContent ..= buf[curposreal]
		print(buf[curposreal])
		tokPos.endPos += 1
		print(buf[curposreal])

		local poo = 1
		for i = 1, 2, 1 do
			if string.find(buf[curposreal+poo], "%x") then
				tokContent ..= buf[curposreal+poo]
				poo += 1
			else
				break;
			end
		end

		if poo ~=1 then
			curposreal += poo
			curpos += poo
			tokPos.endPos += poo - 1
		else
			error({"Invalid string escape.", {Lexer.tokT.strEscape, tokContent, tokPos}, fileref}, 1)
		end
	elseif buf[curposreal] == "u" and buf[curposreal+1] ~= "{" then
		tokContent ..= buf[curposreal]
		tokPos.endPos += 1

		local poo = 1
		for i = 1, 4, 1 do
			if string.find(buf[curposreal+poo], "%x") then
				tokContent ..= buf[curposreal+poo]
				poo += 1
			else
				break;
			end
		end

		if poo ~= 1 then
			curposreal += poo
			curpos += poo
			tokPos.endPos += poo - 1
		else
			error({"Invalid string escape.", {Lexer.tokT.strEscape, tokContent, tokPos}, fileref}, 1)
		end
	elseif buf[curposreal] == "u" and buf[curposreal+1] == "{" then
		tokContent ..= buf[curposreal] .. buf[curposreal+1]
		curposreal += 1
		curpos += 1
		tokPos.endPos += 1

		local poo = 1
		for i = 1, 6, 1 do
			if string.find(buf[curposreal+poo], "%x") then
				tokContent ..= buf[curposreal+poo]
				poo += 1
			else
				break;
			end
		end

		if poo ~=1 then
			if buf[curposreal+poo] == "}" then
				tokContent ..= "}"
				curposreal += poo + 1
				curpos += poo + 1
				tokPos.endPos += poo
			else
				curposreal += poo
				curpos += poo
				tokPos.endPos += poo - 1
				error({"Invalid string escape.", {Lexer.tokT.strEscape, tokContent, tokPos}, fileref}, 1)
			end
		else
			error({"Invalid string escape.", {Lexer.tokT.strEscape, tokContent, tokPos}, fileref}, 1)
		end
	else
		error({"Invalid string escape.", {Lexer.tokT.strEscape, tokContent, tokPos}, fileref}, 1)
	end

	print(tokContent)

	return {Lexer.tokT.strEscape, tokContent, tokPos}
end

--[[
	Reads a double quoted string, goes to state returnNewlineTok if it finds a \n or \r, if there isn't, it just returns to state seekTokens.
]]
local function doubleQuoteStringRead(tokPos:Position)
	local tokContent = ""
	print(buf[curposreal])
	tokPos.startPos = curpos
	tokPos.endPos = curpos

	while buf[curposreal] ~= "\"" and (buf[curposreal] ~= "\n" or buf[curposreal] ~= "\r") and buf[curposreal] ~= "\\" do
		print(buf[curposreal])
		tokContent ..= buf[curposreal]
		curposreal += 1
		curpos += 1
		tokPos.endPos += 1
		print(tokPos)
		if curposreal == #buf then
			error({"Unclosed string.", {Lexer.tokT.strLetters, tokContent, tokPos}, fileref}, 1)
		end
	end

	if buf[curposreal] == "\n" or buf[curposreal] == "\r" then
		lexerState = lexerStates.returnNewlineTok
		returnToState = lexerStates.readStringTwoQuotes
	elseif buf[curposreal] == "\\" and tokContent == "" then
		return stringEscapeRead(tokPos)
	elseif buf[curposreal] == "\\" then
		lexerState = lexerStates.readStringEscape
		returnToState = lexerStates.readStringTwoQuotes
	elseif buf[curposreal] == "\"" and tokContent == "" then
		lexerState = lexerStates.seekTokens
		returnToState = lexerStates.seekTokens
		return readStringQuoteDouble(tokPos)
	elseif buf[curposreal] == "\"" then
		lexerState = lexerStates.readStringQuoteDouble
		returnToState = lexerStates.seekTokens
	else
		lexerState = lexerStates.seekTokens
		returnToState = lexerStates.seekTokens
	end

	print("state:", lexerState, "state to return to:", returnToState)

	print(buf[curposreal])
	return {Lexer.tokT.strLetters, tokContent, tokPos}
end

--[[
	A function that checks if there's a newline.
	It's here for readability, and it makes the code reusable
]]
local function doNewlineCheck(tokPos:Position)
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
			return {Lexer.tokT.newlineReturn, "\r\n", tokPos}
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

			return {Lexer.tokT.newline, whar, tokPos}
		end
	end
	return nil
end

--[[
	initialises a new instance of a lexer so that we can multithread the compilation in the future.
]]
function Lexer.new()
	local instance = setmetatable({}, Lexer)
	return instance
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
	local tokPos = {0, 0, 0}

	local function proceed(amount:number?)
		if amount and amount ~= 1 then
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
		return {Lexer.tokT.eof, "<EOF>", tokPos}
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
		return {Lexer.tokT.tab, spacesntabs, tokPos}
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
				return {Lexer.tokT[aa], resKeywords[i], tokPos}
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
				return {Lexer.tokT.ident, somethingStr, tokPos}
			elseif curchar:find("%u") then
				while curchar ~= "" and curchar ~= nil and curchar do
					curchar = beef[strposreal]
					strpos += 1
					strposreal += 1
					print(curposreal, curpos, curline)
				end
				return {Lexer.tokT.identT, somethingStr, tokPos}
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
					return {Lexer.tokT.peFloat, someth, tokPos}
				else
					return {Lexer.tokT.eFloat, someth, tokPos}
				end
			elseif someth:sub(1,1) == "." then
				return {Lexer.tokT.pFloat, someth, tokPos}
			else
				return {Lexer.tokT.float, someth, tokPos}
			end
		elseif ishex then
			return {Lexer.tokT.hex, someth, tokPos}
		else
			return {Lexer.tokT.int, someth, tokPos}
		end
	--we do some op checks
	elseif buf[curposreal] == ";" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.semicolon, ";", tokPos}
	elseif buf[curposreal] == ":" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.semicolon, ":", tokPos}
	elseif buf[curposreal] == "." then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "." and buf[curposreal+2] == "." then
			proceed(3)
			tokPos.endPos += 2
			return {Lexer.tokT.interval, "...", tokPos}
		else
			proceed()
			return {Lexer.tokT.dot, ".", tokPos}
		end
	elseif buf[curposreal] == "," then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.comma, ",", tokPos}
	elseif buf[curposreal] == "{" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.cuBrakOpen, "{", tokPos}
	elseif buf[curposreal] == "}" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.cuBrakClose, "}", tokPos}
	elseif buf[curposreal] == "(" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.brakOpen, "(", tokPos}
	elseif buf[curposreal] == ")" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.brakClose, ")", tokPos}
	elseif buf[curposreal] == "[" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.sqBrakOpen, "[", tokPos}
	elseif buf[curposreal] == "]" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {Lexer.tokT.sqBrakClose, "]", tokPos}
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
				error({"Unclosed string.", {Lexer.tokT.fStr, maaan, tokPos}, fileref}, 1)
			end
		end
		print(buf[curposreal])
		return {Lexer.tokT.fStr, maaan, tokPos}
	elseif buf[curposreal] == "+" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.addAssign, "+=", tokPos}
		elseif buf[curposreal+1] == "+" then
			proceed(2)
			return {Lexer.tokT.unaryPlus, "++", tokPos}
		else
			proceed()
			return {Lexer.tokT.addOp, "+", tokPos}
		end
	elseif buf[curposreal] == "-" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.subAssign, "-=", tokPos}
		elseif buf[curposreal+1] == "-" then
			proceed(2)
			return {Lexer.tokT.unaryMinus, "--", tokPos}
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return {Lexer.tokT.arrowF, "->", tokPos}
		else
			proceed()
			return {Lexer.tokT.subOp, "-", tokPos}
		end
	elseif buf[curposreal] == "*" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.multAssign, "*=", tokPos}
		else
			proceed()
			return {Lexer.tokT.multOp, "*", tokPos}
		end
	elseif buf[curposreal] == "/" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.divAssign, "/=", tokPos}
		elseif buf[curposreal+1] == "/" then
			proceed(2)
			local maythegodhelpme = "//"
			while buf[curposreal] ~= "\r" or buf[curposreal] ~= "\n" do
				if buf[curposreal] == "\r" or buf[curposreal] == "\n" then
					maythegodhelpme ..= buf[curposreal]
					proceed()
					curline = 1
					return {Lexer.tokT.comment, maythegodhelpme, tokPos}
				else
					maythegodhelpme ..= buf[curposreal]
					proceed()
					print(buf[curposreal])
				end
			end
			return {Lexer.tokT.comment, maythegodhelpme, tokPos}
		elseif buf[curposreal+1] == "*" then
			local maythegodhelpme = buf[curposreal] .. buf[curposreal+1]
			proceed(2)
			while true do
				if curposreal > #buf then
					error({"Unclosed multiline comment.", {Lexer.tokT.multiCom, maythegodhelpme, tokPos}, fileref}, 1)
				elseif buf[curposreal] == "*" and buf[curposreal+1] == "/" then
					print(maythegodhelpme)
					maythegodhelpme ..= buf[curposreal] 
					maythegodhelpme ..= buf[curposreal+1]
					print(maythegodhelpme)
					proceed(2)
					return {Lexer.tokT.multiCom, maythegodhelpme, tokPos}
				else
					maythegodhelpme ..= buf[curposreal]
					proceed()
					tokPos.endPos += 1
				end
			end
		else
			proceed()
			return {Lexer.tokT.divOp, "/", tokPos}
		end
	elseif buf[curposreal] == "%" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.modAssign, "%=", tokPos}
		else
			proceed()
			return {Lexer.tokT.mod, "%", tokPos}
		end
	elseif buf[curposreal] == ">" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.moreOrEqual, ">=", tokPos}
		elseif buf[curposreal+1] == ">" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {Lexer.tokT.bitShiftRAssign, ">>=", tokPos}
			elseif buf[curposreal+2] == ">" then
				if buf[curposreal+3] == "=" then
					proceed(4)
					return {Lexer.tokT.uBitShiftRAssign, ">>>=", tokPos}
				else
					proceed(3)
					return {Lexer.tokT.uBitShiftR, ">>>", tokPos}
				end
			else
				proceed(2)
				return {Lexer.tokT.bitShiftR, ">>", tokPos}
			end
		else
			proceed()
			return {Lexer.tokT.moreOp, ">", tokPos}
		end
	elseif buf[curposreal] == "<" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.lessOrEqual, "<=", tokPos}
		elseif buf[curposreal+1] == "<" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {Lexer.tokT.bitShiftLAssign, "<<=", tokPos}
			else
				proceed(2)
				return {Lexer.tokT.bitShiftL, "<<", tokPos}
			end
		else
			proceed()
			return {Lexer.tokT.lessOp, "<", tokPos}
		end
	elseif buf[curposreal] == "|" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "|" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {Lexer.tokT.orAssign, "||=", tokPos}
			else
				proceed(2)
				return {Lexer.tokT.orOp, "||", tokPos}
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.bitOrAssign, "|=", tokPos}
		else
			proceed()
			return {Lexer.tokT.bitOr, "|", tokPos}
		end
	elseif buf[curposreal] == "&" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "&" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {Lexer.tokT.andAssign, "&&=", tokPos}
			else
				proceed(2)
				return {Lexer.tokT.andOp, "&&", tokPos}
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.bitAndAssign, "&=", tokPos}
		else
			proceed()
			return {Lexer.tokT.bitAnd, "&", tokPos}
		end
	elseif buf[curposreal] == "?" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "?" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {Lexer.tokT.nullCoalAssign, "??=", tokPos}
			else
				proceed(2)
				return {Lexer.tokT.nullCoal, "??", tokPos}
			end
		elseif buf[curposreal+1] == "." then
			proceed(2)
			return {Lexer.tokT.qmarkDot, "?.", tokPos}
		else
			proceed()
			return {Lexer.tokT.questionOp, "?", tokPos}
		end
	elseif buf[curposreal] == "^" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.bitXorAssign, "^=", tokPos}
		else
			proceed()
			return {Lexer.tokT.bitXor, "^", tokPos}
		end
	elseif buf[curposreal] == "=" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {Lexer.tokT.compare, "==", tokPos}
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return {Lexer.tokT.arrowM, "=>", tokPos}
		else
			proceed()
			return {Lexer.tokT.assignOp, "=", tokPos}
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
					error({"Unclosed regexp.", {Lexer.tokT.regexp, aaal, tokPos}, fileref}, 1)
				end
				if buf[curposreal] ~= "/" and buf[curposreal]:find("[%a%d\\r\\n\\t%$%.%*%+%-%^%?%[%]%(%)|{}]") then
					aaal ..= buf[curposreal]
					proceed()
					print(aaal)
					print(buf[curposreal])
				elseif buf[curposreal] == "\r" or buf[curposreal] == "\n" then
					error({"Unclosed regexp.", {Lexer.tokT.regexp, aaal, tokPos}, fileref}, 1)
				end
			end

			if curposreal >= #buf then
				error({"Unclosed regexp.", {Lexer.tokT.regexp, aaal, tokPos}, fileref}, 1)
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
				return {Lexer.tokT.regexp, aaal, tokPos}
			else
				print("WHAT")
				return nil
			end
		else
			return {Lexer.tokT.bitNot, "~", tokPos}
		end
	end
	error({"Unknown symbol.", {0, buf[curposreal], tokPos}, fileref}, 1)
end

return Lexer