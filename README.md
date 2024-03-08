# LuauScript

LuauScript is an interpreted language in very early stages of development with a work-in-progress compiler, and in the future (when byte buffer gets out of studio beta) a VM written in Luau for Roblox.

It is currently planned for it to be able to be precompiled (into bytecode, like Hermes, JVM, ActionScript, or Haxe-specific HashLink, Neko, and CPPIA targets), and then fed to the VM, or compiled on-demand (for example, right before the script is executed, kind of like JavaScript in traditional VMs like V8), and then immidiately executed.


Main modules completion:

- Lexer: ?%
- Parser: ?%
- Bytecode Generator: not started
- VM: not started

Currently considering to change the syntax and other stuff a little bit due to concerns related to implementation complexity, performance, and other things.
