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

## Preprocessor

preprocessor will allow rust-style **macro_func_name!()** macro functions.

for conditional compilation preprocessor will allow rust-style **config!()** macro for inlining into methods, OR **@:config()** metadata for each affected field, but **#if**, **#else**, **#elseif**, and **#end** should remain for those who need them, even though they're a bit harder to read when there's multiple of them, so they create all that awful spaghetti stuff in situations with more complex conditions.

both **@:config()** metadata and **config!()** macro will accept an expression, that will be evaluated in an enviroment, where all config attributes are reachable and valid, and it should be validated by the future language server too, if it ever comes out.

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

The metadata one is a bit more verbose than rust's function-like syntax for that, but is a a lot nicer to read in my opinion, because you don't have to mentally switch from evaluating comparison statements to evaluating this function-like compile-time comparison thing.

## Recommended formatting

1 new line between stuff like functions
camelCase for functions and variables, although snake_case is not prohibited, kebab-case too (UNLIKE LUA)
PascalCase for type and class names
UPPERCASE_SNAKE_CASE for constants
4 spaces for nested lines (2 spaces look awful)

## Unsorted little things

TODO: docgen.
