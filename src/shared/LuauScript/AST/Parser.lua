--!nocheck
local Lexer = require(script.Parent.Lexer)

local Parser = {}
Parser.__index = Parser

local lexr = Lexer.new();

type Module =
{
    --Module name
    name:string,
    mainDef:BaseT,
    subDef:BaseT
}

type BaseT =
{

}

--[[
    Current goals:
    - make a syntax tree that is NOT complicated, and takes only the most important info from tokens (unlike some ASTs that literally include all of the node-related tokens), all of the tokens are ommitted from the AST.
]]

--[[
    TODO: make incremental parsing work. lexing doesn't take much, so compare 2 lexer outputs, and change the AST based on that?
    luau is a pretty "heavy" environment in terms of resource consumption, so this might be useful, also faster build times are always a good thing
]]
function Parser.new(incrementalMode:boolean?)
    local instance = setmetatable({}, Parser)

    if incrementalMode then
        instance.incrMode = incrementalMode
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