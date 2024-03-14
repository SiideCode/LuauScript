# Plans

## Macro system

The macro system should be similar to both Rust and Haxe.

Basically, you can either apply a macro to a field, or make a rust-like !-suffixed macro function that gets replaced with some kind of code.

## Structures

type keyword structs should allow non-anonymous struct declarations inside of them, that should also be separated with ";" from other struct members (mostly for consistency with all of the other struct fields). Example:

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

also allow functions in structs cause why not.

## Preprocessor

why does this need a preprocessor? doing some things during compile-time is FAR better than doing these same things during run-time, because it saves precious resources, and these resources could be spent on doing something else.

preprocessor will allow rust-style **macro_func_name!()** macro functions. TODO: actually decide if **@:build()** will be useful if rust-style macros exist, because, honestly, rust-style macros seem to be superior in every way.

for conditional compilation preprocessor will allow rust-style **cfg!()** macro for inlining into methods, OR **@:cfg()** metadata for each affected field, but **#if**, **#else**, **#elseif**, and **#end** should remain for those who need them, even though they're a bit harder to read when there's multiple of them, so they create all that awful spaghetti stuff in situations with more complex conditions.

both **@:cfg()** metadata and **cfg!()** macro will accept an expression, that will be evaluated in an enviroment, where all config attributes are reachable and valid, and it should be validated by the future language server too, if it ever comes out.

Examples:

``` unknown
@:cfg(config_attribute == value && config_attribute != value)
func someFunction() {}
```

``` unknown
func someFunction()
{
    /*
        during optimisation the compiler will remove this "if"
        entirely, because the statement always evaluates to "true",
        so it'll leave only a single line, which is the
        "doThing()" function call. This would be more useful
        when LuauScript gets a Luau transpiler.
    */
    if (cfg!(config_attribute == value)) then
        doThing();
    else
        doOtherThing();
}
```

The metadata one is a bit more verbose than rust's function-like syntax for that, but is a a lot nicer to read in my opinion, because you don't have to mentally switch from evaluating comparison statements to evaluating this function-like compile-time comparison thing.

## Unsorted little things
