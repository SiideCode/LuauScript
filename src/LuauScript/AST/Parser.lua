--!strict
local Lexer = require(script.Parent.Lexer)

local Parser = {}
Parser.__index = Parser

local lexr = Lexer.new();

export type Position =
{
    startLine:number,
    endline:number,

    startSym:number,
    endSym:number,
}

export type Module =
{
    fileName:string,
    package:PackageDecl?,
    imports:{ImportDecl}?,
    -- type name resolves a conflict with roblox's global Enum type
    enums:{ASTEnum}?,
    structs:{Struct}?,
    classes:{Class}?,
    functions:{Function}?
}

export type Dot =
{
    position:Position
}

export type OrT =
{
    orType:{TypeUnit},
    orPos:Position
}

export type OptT =
{
    isOptional:boolean,
    position:Position
}

export type IdentUnit =
{
    dot:Dot?,
    orType:OrT?,
    optionalT:OptT?,
    unitVal:string,
    -- it can be either a type, or a field.
    isType:boolean,
    position:Position
}

export type PackageDecl =
{
    typeUnits:{IdentUnit},
    position:Position
}

export type FunctionArg =
{
    name:string,
    typeUnits:{TypeIdentUnit},
    colomnPos:Position,
    position:Position
}

export type Function =
{
    name:string,
    arguments:{FunctionArg}?,
    codeBlock:{},
    declarationPos:Position
}

--[[
Current goals:
- make a syntax tree that is NOT complicated, and takes only the most important info from tokens, all of the tokens are ommitted from the AST.
]]

--TODO: make incremental parsing work. lexing doesn't take much, so compare 2 lexer outputs, and change the AST based on that?
local incrMode = true

function Parser.new(incrementalMode:boolean?)
    local instance = setmetatable({}, Parser)

    if incrementalMode then
        incrMode = incrementalMode
    end

    return instance
end

function Parser:parseCodeFile(contents:string, filename:string?)
    local tokenlist = {}
    local tok = {}

    lexr:setScript(contents, filename)

    while tok.t ~= Lexer.tokT.eof do
        tok = lexr:nextToken()
        table.insert(tokenlist, tok)
    end

    return self:parseTokenArray(tokenlist)
end

function Parser:parseTokenArray(tokArr:{Lexer.Token})
    for k, v in pairs(tokArr) do
        
    end
end

return Parser