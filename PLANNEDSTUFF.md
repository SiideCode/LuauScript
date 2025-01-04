# Plans

TODO: move it all into issues

## Structures

structs should allow non-anonymous struct declarations inside of them. Example:

```unknown
package;

struct struct_name =
{
    struct innerstruct_name =
    {
        var data:Int;
        var otherData:String;
    };
    var data:Int;
    var otherData:String;
}
```

## Preprocessor & Macros

They will allow rust-style **macro_func_name!()** macro functions. @build(macroBuildFunc()) macros will remain to work like a more complicated version of python's decorators, will work for classes and functions.

To ommit code, according to a condition, they will allow rust-style **config!()** macro for inlining into methods, OR **@:config()** metadata for each affected field, but **#if**, **#else**, **#elseif**, and **#end** should remain for those who need them, or situations in which it makes more sense to use them, even though they create awful spaghetti in situations with complex conditions.

Preprocessing is evaluated before the lexing step, processes everything that starts with a #, and some of the metadata.
Macros are evaluated before the parsing step, processes everything else.

Both **@:config()** metadata and **config!()** macro will accept an expression, that will be evaluated in an enviroment, where all config attributes are reachable and valid, and it should be validated by the future language server too (if it ever gets done lol).

Examples:

```unknown
@:config(config_attribute == value && config_attribute != value)
function someFunction() {}
```

```unknown
function someFunction()
{
    /*
        as an optimisation the compiler will remove this "if"
        entirely, because the statement always evaluates to "true",
        so it'll leave only a single line, which is the
        "doThing()" function call.
    */
    if (config!(config_attribute == value)) then
        doThing();
    else
        doOtherThing();
}
```

The metadata one is a bit more verbose than rust's function-like macros, but is a a lot nicer to read in my opinion, because you don't have to mentally switch from evaluating comparison statements to evaluating this function-like compile-time weird comparison thing.

## Recommended formatting?

1 new line between stuff like functions
camelCase for functions and variables, although snake_case is not prohibited, kebab-case too (UNLIKE LUA)
PascalCase for type and class names, although camelCase, snake_case, and kebab-case is supported, although it's recommended to have them start with an uppercase
UPPERCASE_SNAKE_CASE for constants, but it's just a recommendation
4 spaces for nested lines (2 spaces look awful)

## Unsorted little things

TODO: docgen for the build tools, VM, and everything else like this.

TODO: docgen for the language API (eventually).

TODO: some simple demo projects, game integration examples, all that kind of stuff.

(MAYBE) Nominal typing with an option for structural typing? (idea taken from https://github.com/Draco-lang/Language-suggestions/issues/17)

Think about execution: start ONLY from Main, or treat a file with code outside of blocks as a Main (like Lua/Python), or both (toggleable with a definition of a compile-time define)?
If it starts only from main, or both, then there should be a double-main system, and a module sharing system for the luau-roblox transpiler target in the future?

Gotta make sure something like this:

```haxe
class Test {
    static function main() {
        var funcscope = 6;
        // 6
        trace(funcscope);

        {
            var anotherscope = 7;
            // 7
            trace(anotherscope);
        }
        // null
        trace(anotherscope);
    }
}
```

preserves scoping when possible, for example, in luau it's (basically) equivalent to:

```lua
local funcscope = 6
-- 6
print(funcscope)

do
    local anotherscope = 7
    -- 7
    print(anotherscope)
end
-- nil
print(anotherscope)
```

reference anotherscope gets invalidated when the program leaves its scope, causing its value of 7 to become GCable.

Allow nested comments like in ODIN (and a small amount of other languages):

```odin
/*
    comm
    /*
        comm
    */
*/
```

Allow number separators like in js (and now haxe):

```javascript
// equivalent to 204407340
let h = 204_407_340;
```

Variable shadowing (MAYBE make some way to confirm that you WANT to shadow the variable, especially if both are defined in the same scope):

```haxe
var hello = 3;
// 3
trace(hello);

var hello = 6;
// 6
trace(hello);
```

(MAYBE) Add characters-as-codes by default like in C:

```C
char h = "h";
```

that gets converted into something like

```lua
local h = 68
```

and gets converted into a string, when used with a string (implicitly)

```lua
-- "h"
print(string.char(h));
```

Add syntax highlighting for multi-line string content (someday) (useful for something like JSON, or literally luau code) (idea from https://github.com/fsharp/fslang-suggestions/issues/1300)

(MAYBE) Question mark access aka safe navigation (Object?.field or (unlikely) ?array\[number\] or field?.function(arg)) that checks if the thing exists, and either returns a null, or an "undefined" string.

Add ternary operator later (important)

(MAYBE) A @:noTailRecurse metadata to force no tail recursion optimisation for the line (warns if tail recursion isn't possible in the first place). Useful for cases where you NEED actual recursion for some reason.

Everything should be an expression, like in haxe (literally just a nice feature that you can either use or not and nobody would care)

Union types instead of Haxe's Either<Left, Right> enum, OR add a similar explicit way of handling union types, BUT with support for more than 2 types (or just add both).

Int ranges (0...4) should be including (means it'll go 0, 1, 2, 3, 4) as it is less confusing for newbies and lua users

Rest arguments like in haxe (function name(...arg:Type))

Named arguments like in ODIN (https://odin-lang.org/docs/overview/#named-arguments) and python. This allows multiple Rest<> args and non-positional args.

(MAYBE) Take ideas from these Haxe Evolution proposals: [this](https://github.com/HaxeFoundation/haxe-evolution/pull/117/commits/6b759041ea6547b76b56ce66495ef621e625fb98) (the rest arg functions especially), [this](https://github.com/HaxeFoundation/haxe-evolution/pull/111) and [this](https://github.com/HaxeFoundation/haxe-evolution/pull/96), also [this](https://github.com/HaxeFoundation/haxe-evolution/pull/95), [this](https://github.com/HaxeFoundation/haxe-evolution/pull/86) and [this haxe pull](https://github.com/HaxeFoundation/haxe/pull/11558)

(MAYBE) If there's gonna be globals, then add shared globals, probably with write safety settings (server-write only, or both server and client write, or even client-only).
