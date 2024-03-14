# LuauScript

## Info

LuauScript is an interpreted language in very early stages of development with a work-in-progress compiler, and in the future (when byte buffer gets out of studio beta) a VM written in Luau for Roblox.

The language is inspired by  Haxe/ActionScript, Lua/Luau, Rust, and very slightly by Zig and Go.

It is currently planned for it to be able to be compiled entirely before execution or compiled right before the execution, both for Roblox experience modding. It is also planned to make it transpile into Luau, but it's currently low priority, because it's mainly made for roblox game modding.

## Main modules completion (in order of priority)

- Lexer: 80-ish%
- Parser: <1%
- Bytecode Compiler: not started
- VM: not started
- Luau Transpiler: not started

## Note

Currently considering to change the syntax and other stuff a little bit due to concerns related to implementation complexity, performance, and other things.

## How to include in your rojo project (WIP)

1. get [Rojo](https://rojo.space)
2. get [Wally](https://wally.run)
3. run "wally install *package-name*"
4. done.
