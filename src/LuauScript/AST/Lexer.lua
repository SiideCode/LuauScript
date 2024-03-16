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
	t:number,
	value:string?,
	position:Position
}

type LexerError = {
	msg:string,
	lastToken:Token,
	fileRef:string?
}

--current position in file
local curposreal = 1
--current position in line
local curpos = 1
--current line
local curline = 1
--list of characters
local buf = {}
--name of the file
local fileref = ""
--current state of the lexer
local lexerState = 1
--state that should be next after the current state
local returnToState = 1
local tokPos = {startPos = 0, line = 0, endPos = 0}

Lexer.tokTMirror = {}
--TODO: make this list more maintainable (make a function that accepts and array, and maps numbers in range x...y to everything)
local tokProt =
{
	"unknown",							-- unknown symbol
	"eof",								-- EOF
	"tab",								-- tabulation
	"newlineReturn",					-- carriage return and new line
	"newline",							-- new line or carriage return
	-- TODO: add binary numbers
	"hex",								-- hexadecimal number
	"int",								-- integer
	"float",							-- floating point
	"pFloat",							-- floating point no whole part
	"peFloat",							-- floating point exponent no whole part
	"eFloat",							-- floating point exponent
	"intInt",							-- integer interval
	"comment",							-- one line comment
	"unaryPlus",						-- unary +1
	"unaryMinus",						-- unary -1
	"bitNot",							-- bitwise not (every 1 = 0, every 0 = 1).
	"modAssign",						-- module + assign
	"bitAndAssign",						-- bitwise AND + assign
	"bitOrAssign",						-- bitwise OR + assign
	"bitXorAssign",						-- bitwise XOR + assign
	"addAssign",						-- add + assign
	"subAssign",						-- substract + assign
	"multAssign",						-- multiply + assign
	"divAssign",						-- divide + assign
	"bitShiftLAssign",					-- bit shift left + assign
	"bitShiftRAssign",					-- bit shift right + assign
	"uBitShiftRAssign",					-- unsigned bit shift left
	"orAssign",							-- or + assign
	"andAssign",						-- and + assign
	"nullCoalAssign",					-- null coalescing + assign (https://www.tutorialspoint.com/What-is-a-null-coalescing-operator-in-JavaScript)
	"compare",							-- compare
	"notEqual",							-- not equals
	"lessOrEqual",						-- less/equals
	"moreOrEqual",						-- more/equals
	"andOp",							-- and
	"orOp",								-- or
	"bitShiftL",						-- bit shift left
	"bitShiftR",						-- bit shift right
	"uBitShiftR",						-- unsigned bit shift right
	"arrowF",							-- arrow (https://haxe.org/manual/expression-arrow-function.html) (https://haxe.org/manual/lf-function-bindings.html)
	"interval",							-- interval from...to
	"arrowM",							-- arrow (for map and array loops with indexes)
	"notOp",							-- not
	"lessOp",							-- less
	"moreOp",							-- more
	"semicolon",						-- semicolon
	"colon",							-- colon
	"comma",							-- comma
	"dot",								-- dot
	"qmarkDot",							-- question mark + dot (https://bobbyhadz.com/blog/tscript-question-mark-dot)
	"mod",								-- module
	"bitAnd",							-- bitwise and
	"bitOr",							-- bitwise or
	"bitXor",							-- bitwise XOR
	"addOp",							-- add
	"multOp",							-- multiply
	"divOp",							-- divide
	"subOp",							-- substract
	"assignOp",							-- assign
	"sqBrakOpen",						-- open square brackets
	"sqBrakClose",						-- close square brackets
	"cuBrakOpen",						-- open curly brackets
	"cuBrakClose",						-- close curly brackets
	"brakOpen",							-- open brackets
	"brakClose",						-- close brackets
	"nullCoal",							-- null coalescing (https://www.tutorialspoint.com/What-is-a-null-coalescing-operator-in-JavaScript)
	"questionOp",						-- question mark
	"atMacro",							-- at (macros)
	"multiCom",							-- begin multiline comment
	"str",								-- start/begin string ("")
	"fStr",								-- start/begin formatted string ('')
	"strLetters",						-- string letters
	"strEscape",						-- escapes in strings
	"fStrDollarContent",				-- everything after $, between ${ and }. $$ just adds a $ to fStr.
	--(haxe regexp rules: https://haxe.org/manual/std-regex.html)
	"regexp",							-- start/end of the regexp (https://haxe.org/manual/std-regex.html)
	--TODO: make it work lol, i forgot it exists
	"hashtag",							-- i forgot why it exists.
	"dollar",							-- dollar for something
	--keywords
	"kvPackage",						-- module path declaration keyword
	"kvImport",							-- module import keyword
	"kvUsing",							-- using (https://haxe.org/manual/lf-static-extension.html)
	"kvClass",							-- class declaration keyword
	"kvInterface",						-- interface keyword
	"kvEnum",							-- enum keyword
	"kvAbstract",						-- abstract type/class/enum modifier keyword (https://haxe.org/manual/ts-abstract.html) (https://haxe.org/manual/ts-abstract-class.html)
	"kvType",							-- type declaration keyword, only useful for type alias declarations (works like haxe's typedef, but you can't declare structs like this)
	"kvStruct",							-- struct declaration keyword. it's only there cause i LOVE the struct keyword for some reason. type and struct separation is rust-like at it's core now, and i love it, even tho i don't really like rust
	"kvExtends",						-- class extension keyword
	"kvImplements",						-- interface implementation keyword
	"kvExtern",							-- extern keyword (https://haxe.org/manual/lf-externs.html)
	"kvGlobal",							-- global modifier
	"kvLocal",							-- local modifier
	"kvOverride",						-- override modifier, overloads the function
	"kvDynamic",						-- dynamic access to a variable i guess
	"kvInline",							-- inline keyword
	"kvMacro",							-- macro class/func/var/whatever modifier.
	"kvConst",							-- constant (might get unused, cause it can only be emulated)
	"kvOperator",						-- operator function modifier keyword
	"kvOverload",						-- overloading keyword
	"kvFunc",							-- function keyword
	"kvVar",							-- variable keyword
	"kvNull",							-- null
	"kvTrue",							-- true
	"kvFalse",							-- false
	"kvThis",							-- basically like self in lua
	"kvIf",								-- if
	"kvElse",							-- else
	"kvWhile",							-- while
	"kvDo",								-- do
	"kvFor",							-- for
	"kvBreak",							-- break
	"kvContinue",						-- continue
	"kvReturn",							-- return
	"kvSwitch",							-- switch
	"kvCase",							-- case
	"kvDefault",						-- default course of action for switch case/variable access modifier AND default access modifier for variables (no getter/setter)
	"kvThrow",							-- throw an error
	"kvTry",							-- try
	"kvCatch",							-- catch
	"kvUntyped",						-- suppress typechecker for the line entirely
	"kvNew",							-- new() constructor
	"kvIn",								-- in for the for-loop
	--TODO: decide on how to do casts (possibly allow C-style unsafe casts, or C++-style cast functions?)
	"kvCast",							-- cast. read https://haxe.org/manual/expression-cast-unsafe.html and https://haxe.org/manual/expression-cast-safe.html
	"ident",							-- packages and variables.
	"identT",							-- classes and types
	"identMacro"						-- rust-like macro_funcion! identifier
}

local fakei = 0

for i = 1, #tokProt, 1 do
	table.insert(Lexer.tokTMirror, fakei, tokProt[i]);
	fakei += 1
end

--be sure to let the GC dispose of temps to reduce resource usage slightly :)
fakei = nil
tokProt = nil

Lexer.tokT = TableUtil.DictUtil.mirrorDictionary(Lexer.tokTMirror)

--List of reserved keywords. TODO: consider keyword alias support, will be useful to not instantly introduce breaking changes if i change my mind about keywords during non-stable development phase.
local resKeywords =
{
	"package",
	"import",
	"using",
	"class",
	"interface",
	"enum",
	"abstract",
	"type",
	"struct",
	"extends",
	"implements",
	"global",
	"local",
	"override",
	"dynamic",
	"inline",
	"macro",
	"const",
	"operator",
	"overload",
	"func",
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
	--reads a single line comment, includes markdown and other stuff to support docs
	readComment = 4,
	--reads a multiline comment, includes markdown and other stuff to support docs
	readMultiComment = 5,
	--just returns a newline if there's one, and that's it
	returnNewlineTok = 6,
	--reads and returns a string escape
	readStringEscape = 7,
	--reads and returns a quote of a string
	readStringQuote = 8,
	readFStringDollar = 9
}

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

local function readCommentBegin()
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	local comm = ""

	
end

local function readStringQuote()
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	local crol = ""

	if buf[curposreal] == "\"" then
		crol = "\""
	elseif buf[curposreal] == "\'" then
		crol = "'"
	end

	tokPos.startPos = curpos
	tokPos.endPos = curpos
	curpos += 1
	curposreal += 1

	if crol == "'" then
		return {t = Lexer.tokT.fStr, value = crol, position = tokPos}
	end
	return {t = Lexer.tokT.str, value = crol, position = tokPos}
end

--TODO: revamp this someday, i don't like it.
local function stringEscapeRead()
	lexerState = returnToState
	local tokContent = ""

	tokPos.startPos = curpos
	tokPos.endPos = curpos

	if buf[curposreal] == "\\" then
		tokContent ..= "\\"
		curposreal += 1
		curpos += 1
	else
		error("A STRING ESCAPE ERROR OCCURED! PLEASE SEND THIS TO THE DEVELOPER!")
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
			error({msg = "Invalid string escape.", lastToken = {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}, fileRef = fileref}, 1)
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
			error({msg = "Invalid string escape.", lastToken = {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}, fileRef = fileref}, 1)
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
				error({msg = "Invalid string escape.", lastToken = {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}, fileRef = fileref}, 1)
			end
		else
			error({msg = "Invalid string escape.", lastToken = {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}, fileRef = fileref}, 1)
		end
	else
		error({msg = "Invalid string escape.", lastToken = {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}, fileRef = fileref}, 1)
	end

	print(tokContent)

	return {t = Lexer.tokT.strEscape, value = tokContent, position = tokPos}
end

local function readFStringDollar()
	local lel = buf[curposreal]
	if buf[curposreal]:find("[_%a]") then
		curpos += 1
		curposreal += 1
		while buf[curposreal]:find("[_%a%d]") do
			curpos += 1
			curposreal += 1
			tokPos.endPos += 1
			lel ..= buf[curposreal]
		end
	else
		error({msg = "Nothing to format", lastToken = {t = Lexer.tokT.fStrDollarContent, value = lel, position = tokPos}, 1})
	end
	return {t = Lexer.tokT.fStrDollarContent, value = lel, position = tokPos}
end

local function stringRead()
	local tokContent = ""
	print(buf[curposreal])
	tokPos.startPos = curpos
	tokPos.endPos = curpos

	--TODO: make all strings multilinable why did i not do that from the beginnign aiioWJF
	if buf[curposreal] ~= "$" and lexerState ~= lexerStates.readStringOneQuote then
		while buf[curposreal] ~= "\"" and (buf[curposreal] ~= "\n" or buf[curposreal] ~= "\r") and buf[curposreal] ~= "\\" do
			print(buf[curposreal])
			tokContent ..= buf[curposreal]
			curposreal += 1
			curpos += 1
			tokPos.endPos += 1
			print(tokPos)
			if curposreal == #buf then
				error({msg = "Unclosed string.", lastToken = {Lexer.tokT.strLetters, tokContent, tokPos}, fileRef = fileref}, 1)
			end
		end
	end

	if buf[curposreal] == "\n" or buf[curposreal] == "\r" then
		returnToState = lexerStates.readStringTwoQuotes
		lexerState = lexerStates.returnNewlineTok
	elseif buf[curposreal] == "\\" and tokContent == "" then
		return stringEscapeRead(tokPos)
	elseif buf[curposreal] == "\\" then
		returnToState = lexerState
		lexerState = lexerStates.readStringEscape
	elseif (buf[curposreal] == "\"" or buf[curposreal] == "'") and tokContent == "" then
		lexerState = lexerStates.seekTokens
		returnToState = lexerStates.seekTokens
		return readStringQuote(tokPos)
	elseif (buf[curposreal] == "\"" or buf[curposreal] == "'") then
		lexerState = lexerStates.readStringQuote
		returnToState = lexerStates.seekTokens
	elseif buf[curposreal] == "$" and tokContent == "" and lexerState == lexerStates.readStringOneQuote then
		returnToState = lexerState
		lexerState = lexerStates.readFStringDollar
		return readFStringDollar(tokPos)
	elseif buf[curposreal] == "$" and lexerState == lexerStates.readStringOneQuote then
		returnToState = lexerState
		lexerState = lexerStates.readFStringDollar
	else
		lexerState = lexerStates.seekTokens
		returnToState = lexerStates.seekTokens
	end

	print("state:", lexerState, "state to return to:", returnToState)

	print(buf[curposreal])
	return {t = Lexer.tokT.strLetters, value = tokContent, position = tokPos}
end

local function doNewlineCheck()
	lexerState = returnToState
	print("state:", lexerState, "state to return:", returnToState)

	if buf[curposreal] == "\n" or buf[curposreal] == "\r" then
		tokPos.startPos = curpos
		if buf[curposreal] == "\r" and buf[curposreal+1] == "\n" then
			tokPos.endPos = curpos + 1
			curline += 1
			curpos = 2
			curposreal += 2
			return {t = Lexer.tokT.newlineReturn, value = "\r\n", position = tokPos}
		else
			local whar = "\n"
			if buf[curposreal-1] == "\r" then
				whar = "\r"
			end

			tokPos.endPos = curpos
			curline += 1
			curpos = 1
			curposreal += 1

			return {t = Lexer.tokT.newline, value = whar, position = tokPos}
		end
	end
	return nil
end

--[[
	initialises a new instance of a lexer so that we can multithread the compilation in the future if the lexer stage gets a bit too slow for whatever reason.
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
	Might be useful if you want to turn the script into lexemes again from the beginning.
]]
function Lexer:resetState()
	curposreal = 1
	curpos = 1
	curline = 1
	lexerState = 1
end

function Lexer:nextToken()
	tokPos = {startPos = 0, line = 0, endPos = 0}

	--print("finding token, current state is", lexerState)

	tokPos.line = curline

	if lexerState ~= lexerStates.seekTokens then
		if lexerState == lexerStates.readStringTwoQuotes or lexerState == lexerStates.readStringOneQuote then
			return stringRead()
		elseif lexerState == lexerStates.readStringQuote then
			return readStringQuote()
		elseif lexerState == lexerStates.readStringEscape then
			return stringEscapeRead()
		elseif lexerState == lexerStates.readCommentBegin then
			return readCommentBegin();
		elseif lexerState == lexerStates.readComment then
			error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.readMultiCommentStart then
			return 
		elseif lexerState == lexerStates.readMultiCommentEnd then
			return 
		elseif lexerState == lexerStates.readMultiComment then
			error("UNIMPLEMENTED")
		elseif lexerState == lexerStates.returnNewlineTok then
			return doNewlineCheck()
		end
	end

	if #buf == 0 or curposreal > #buf then
		return {t = Lexer.tokT.eof, value = "<EOF>", position = tokPos}
	end

	if buf[curposreal] == " " or buf[curposreal] == "\t" then
		local spacesntabs = ""
		tokPos.startPos = curpos
		while buf[curposreal] == " " or buf[curposreal] == "\t" do
			spacesntabs ..= buf[curposreal]
			proceed()
		end
		tokPos.endPos = curpos
		return {t = Lexer.tokT.tab, value = spacesntabs, position = tokPos}
	end

	local apossiblenewline = doNewlineCheck(tokPos)
	if apossiblenewline ~= nil then
		return apossiblenewline
	end

	if buf[curposreal]:find("[_%a]") then
		local somethingStr = ""
		tokPos.startPos = curpos

		while buf[curposreal]:find("[_%a%d]") do
			somethingStr ..= buf[curposreal]
			proceed()
		end

		if buf[curposreal] == "!" then
			somethingStr ..= buf[curposreal]
			proceed()
		end

		tokPos.endPos = curpos

		for i in ipairs(resKeywords) do
			if somethingStr == resKeywords[i] then
				local aa = "kv" .. resKeywords[i]:sub(1, 1):upper() .. resKeywords[i]:sub(2)
				return {t = Lexer.tokT[aa], value = resKeywords[i], position = tokPos}
			end
		end

		if somethingStr:sub(1):find("[_%l%u]") then
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
				end
				if beef[strposreal] == "!" then
					strpos += 1
					strposreal += 1
				end
				return {t = Lexer.tokT.ident, value = somethingStr, position = tokPos}
			elseif beef[strposreal]:find("%u") then
				while beef[strposreal] ~= "" and beef[strposreal] ~= nil and beef[strposreal] do
					beef[strposreal] = beef[strposreal]
					strpos += 1
					strposreal += 1
				end
				return {t = Lexer.tokT.identT, value = somethingStr, position = tokPos}
			end
		end
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
					return {t = Lexer.tokT.peFloat, value = someth, position = tokPos}
				else
					return {t = Lexer.tokT.eFloat, value = someth, position = tokPos}
				end
			elseif someth:sub(1,1) == "." then
				return {t = Lexer.tokT.pFloat, value = someth, position = tokPos}
			else
				return {t = Lexer.tokT.float, value = someth, position = tokPos}
			end
		elseif ishex then
			return {t = Lexer.tokT.hex, value = someth, position = tokPos}
		else
			return {t = Lexer.tokT.int, value = someth, position = tokPos}
		end
	--TODO: make all of these into 1 function
	elseif buf[curposreal] == ";" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.semicolon, value = ";", position = tokPos}
	elseif buf[curposreal] == ":" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.colon, value = ":", position = tokPos}
	elseif buf[curposreal] == "." then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "." and buf[curposreal+2] == "." then
			proceed(3)
			tokPos.endPos += 2
			return {t = Lexer.tokT.interval, value = "...", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.dot, value = ".", position = tokPos}
		end
	elseif buf[curposreal] == "," then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.comma, value = ",", position = tokPos}
	elseif buf[curposreal] == "{" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.cuBrakOpen, value = "{", position = tokPos}
	elseif buf[curposreal] == "}" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.cuBrakClose, value = "}", position = tokPos}
	elseif buf[curposreal] == "(" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.brakOpen, value = "(", position = tokPos}
	elseif buf[curposreal] == ")" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.brakClose, value = ")", position = tokPos}
	elseif buf[curposreal] == "[" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.sqBrakOpen, value = "[", position = tokPos}
	elseif buf[curposreal] == "]" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		proceed()
		return {t = Lexer.tokT.sqBrakClose, value = "]", position = tokPos}
	elseif buf[curposreal] == "\"" then
		lexerState = lexerStates.readStringTwoQuotes
		returnToState = lexerStates.readStringTwoQuotes
		return readStringQuote(tokPos)
	elseif buf[curposreal] == "'" then
		lexerState = lexerStates.readStringOneQuote
		returnToState = lexerStates.readStringOneQuote
		return readStringQuote(tokPos)
	elseif buf[curposreal] == "+" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.addAssign, value = "+=", position = tokPos}
		elseif buf[curposreal+1] == "+" then
			proceed(2)
			return {t = Lexer.tokT.unaryPlus, value = "++", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.addOp, value = "+", position = tokPos}
		end
	elseif buf[curposreal] == "-" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.subAssign, value = "-=", position = tokPos}
		elseif buf[curposreal+1] == "-" then
			proceed(2)
			return {t = Lexer.tokT.unaryMinus, value = "--", position = tokPos}
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return {t = Lexer.tokT.arrowF, value = "->", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.subOp, value = "-", position = tokPos}
		end
	elseif buf[curposreal] == "*" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.multAssign, value = "*=", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.multOp, value = "*", position = tokPos}
		end
	elseif buf[curposreal] == "/" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.divAssign, value = "/=", position = tokPos}
		elseif buf[curposreal+1] == "/" then
			proceed(2)
			local maythegodhelpme = "//"
			while buf[curposreal] ~= "\r" or buf[curposreal] ~= "\n" do
				maythegodhelpme ..= buf[curposreal]
				proceed()
				curline = 1
				return {t = Lexer.tokT.comment, value = maythegodhelpme, position = tokPos}
			end
			maythegodhelpme ..= buf[curposreal]
			proceed()
			print(buf[curposreal])
			return {t = Lexer.tokT.comment, value = maythegodhelpme, position = tokPos}
		elseif buf[curposreal+1] == "*" then
			local maythegodhelpme = buf[curposreal] .. buf[curposreal+1]
			proceed(2)
			while true do
				if curposreal > #buf then
					error({msg = "Unclosed multiline comment.", lastToken = {t = Lexer.tokT.multiCom, value = maythegodhelpme, position = tokPos}, fileRef = fileref}, 1)
				elseif buf[curposreal] == "*" and buf[curposreal+1] == "/" then
					print(maythegodhelpme)
					maythegodhelpme ..= buf[curposreal] 
					maythegodhelpme ..= buf[curposreal+1]
					print(maythegodhelpme)
					proceed(2)
					return {t = Lexer.tokT.multiCom, value = maythegodhelpme, position = tokPos}
				else
					maythegodhelpme ..= buf[curposreal]
					proceed()
					tokPos.endPos += 1
				end
			end
		else
			proceed()
			return {t = Lexer.tokT.divOp, value = "/", position = tokPos}
		end
	elseif buf[curposreal] == "%" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.modAssign, value = "%=", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.mod, value = "%", position = tokPos}
		end
	elseif buf[curposreal] == ">" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.moreOrEqual, value = ">=", position = tokPos}
		elseif buf[curposreal+1] == ">" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {t = Lexer.tokT.bitShiftRAssign, value = ">>=", position = tokPos}
			elseif buf[curposreal+2] == ">" then
				if buf[curposreal+3] == "=" then
					proceed(4)
					return {t = Lexer.tokT.uBitShiftRAssign, value = ">>>=", position = tokPos}
				else
					proceed(3)
					return {t = Lexer.tokT.uBitShiftR, value = ">>>", position = tokPos}
				end
			else
				proceed(2)
				return {t = Lexer.tokT.bitShiftR, value = ">>", position = tokPos}
			end
		else
			proceed()
			return {t = Lexer.tokT.moreOp, value = ">", position = tokPos}
		end
	elseif buf[curposreal] == "<" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.lessOrEqual, value = "<=", position = tokPos}
		elseif buf[curposreal+1] == "<" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {t = Lexer.tokT.bitShiftLAssign, "<<=", tokPos}
			else
				proceed(2)
				return {t = Lexer.tokT.bitShiftL, value = "<<", position = tokPos}
			end
		else
			proceed()
			return {t = Lexer.tokT.lessOp, value = "<", position = tokPos}
		end
	elseif buf[curposreal] == "|" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "|" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {t = Lexer.tokT.orAssign, value = "||=", position = tokPos}
			else
				proceed(2)
				return {t = Lexer.tokT.orOp, value = "||", position = tokPos}
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.bitOrAssign, value = "|=", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.bitOr, value = "|", position = tokPos}
		end
	elseif buf[curposreal] == "&" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "&" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {t = Lexer.tokT.andAssign, value = "&&=", position = tokPos}
			else
				proceed(2)
				return {t = Lexer.tokT.andOp, value = "&&", position = tokPos}
			end
		elseif buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.bitAndAssign, value = "&=", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.bitAnd, value = "&", position = tokPos}
		end
	elseif buf[curposreal] == "?" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "?" then
			if buf[curposreal+2] == "=" then
				proceed(3)
				return {t = Lexer.tokT.nullCoalAssign, value = "??=", position = tokPos}
			else
				proceed(2)
				return {t = Lexer.tokT.nullCoal, value = "??", position = tokPos}
			end
		elseif buf[curposreal+1] == "." then
			proceed(2)
			return {t = Lexer.tokT.qmarkDot, value = "?.", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.questionOp, value = "?", position = tokPos}
		end
	elseif buf[curposreal] == "^" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.bitXorAssign, value = "^=", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.bitXor, value = "^", position = tokPos}
		end
	elseif buf[curposreal] == "=" then
		tokPos.startPos = curpos
		tokPos.endPos = curpos
		if buf[curposreal+1] == "=" then
			proceed(2)
			return {t = Lexer.tokT.compare, value = "==", position = tokPos}
		elseif buf[curposreal+1] == ">" then
			proceed(2)
			return {t = Lexer.tokT.arrowM, value = "=>", position = tokPos}
		else
			proceed()
			return {t = Lexer.tokT.assignOp, value = "=", position = tokPos}
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
					error({msg = "Unclosed regexp.", lastToken = {t = Lexer.tokT.regexp, value = aaal, position = tokPos}, fileRef = fileref}, 1)
				end
				if buf[curposreal] ~= "/" and buf[curposreal]:find("[%a%d\\r\\n\\t%$%.%*%+%-%^%?%[%]%(%)|{}]") then
					aaal ..= buf[curposreal]
					proceed()
					print(aaal)
					print(buf[curposreal])
				elseif buf[curposreal] == "\r" or buf[curposreal] == "\n" then
					error({msg = "Unclosed regexp.", lastToken = {t = Lexer.tokT.regexp, value = aaal, position = tokPos}, fileRef = fileref}, 1)
				end
			end

			if curposreal >= #buf then
				error({msg = "Unclosed regexp.", lastToken = {t = Lexer.tokT.regexp, value = aaal, position = tokPos}, fileRef = fileref}, 1)
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
				return {t = Lexer.tokT.regexp, value = aaal, position = tokPos}
			else
				print("WHAT")
				return nil
			end
		else
			return {t = Lexer.tokT.bitNot, value = "~", position = tokPos}
		end
	end
	error({"Unknown symbol.", {t = 0, value = buf[curposreal], position = tokPos}, fileref}, 1)
end

return Lexer