# Plans

## Macro system

The macro system should be similar to both Rust and Haxe.

Basically, you can either apply a macro to a field, or make a rust-like !-suffixed macro function that gets replaced with some kind of code/value.

## Structures

structs should allow non-anonymous struct declarations inside of them. Example:

``` unknown
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

## Preprocessor & Macro

They will allow rust-style **macro_func_name!()** macro functions.

To ommit code, according to a condition, they will allow rust-style **config!()** macro for inlining into methods, OR **@:config()** metadata for each affected field, but **#if**, **#else**, **#elseif**, and **#end** should remain for those who need them, or situations in which it makes more sense to use them, even though they create awful spaghetti in situations with complex conditions.

Preprocessing is evaluated before the lexing step, processes everything that starts with a #, and some of the metadata.
Macros are evaluated before the parsing step, processes everything else.

Both **@:config()** metadata and **config!()** macro will accept an expression, that will be evaluated in an enviroment, where all config attributes are reachable and valid, and it should be validated by the future language server too (if it ever gets done lol).

Examples:

``` unknown
@:config(config_attribute == value && config_attribute != value)
function someFunction() {}
```

``` unknown
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

## Recommended formatting

1 new line between stuff like functions
camelCase for functions and variables, although snake_case is not prohibited, kebab-case too (UNLIKE LUA)
PascalCase for type and class names, although camelCase, snake_case, and kebab-case is supported, although it's recommended to have them start with an uppercase
UPPERCASE_SNAKE_CASE for constants, but it's just a recommendation
4 spaces for nested lines (2 spaces look awful)

## Unsorted little things

TODO: docgen for the build tools, VM, and everything else like this.

TODO: docgen for the language API (eventually).

TODO: some simple demo projects, game integration examples, all that kind of stuff.

Possibly nominal typing with an option for structural typing? (idea taken from https://github.com/Draco-lang/Language-suggestions/issues/17)