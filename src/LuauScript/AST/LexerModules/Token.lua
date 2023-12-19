--!strict
local Token = {}
Token.__index = Token

local posModule = require(script.Parent.Pos)

--enum
Token.tokT =
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
	--TODO: decide if it's needed later
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

-- Create a new token, can either contain a string as a value, or nothing
function Token:new(type:number, value:string?, position:posModule)
	local instance = {}
	setmetatable(instance, self)

	--number
	instance.type = type
	print(instance.type)

	--string
	instance.value = value
	print(instance.value)

	instance.position = position

	return instance
end

function Token:getParams():(number, string, posModule)
	return self.type, self.value, self.position
end

function Token:getTypeString(type:number):number?
	return table.find(self.tokT, type)
end

function Token:toString():string
	return self.type .. " " .. self.value .. " " .. self.position
end

return Token
