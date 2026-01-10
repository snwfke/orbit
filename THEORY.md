# Theory
The idea behind orbit can be best described as: "if I could code this better in a different language, why should I be forced to use this one [Lua]?"

In order to write a tool that converts code from one language directly into another, we'll need to break down our theory of how to do it
by abstracting the principles, finding a motive, and guaranteeing a realistic code implementation.

## Abstract
DCS World uses Lua as the primary language for its scripting engine, which we will refer to from hereon as
the "Lua API." the DCS Lua API interoperates with the Eagle Dynamics Graphics Engine, (EDGE) written in C++
and known as the "C++ API."

Both APIs communicate with one another to achieve desired game behaviour, however,
modding in DCS sometimes requires you to mess with both languages – you've probably yet to meet a full-stack
developer whose said "oh, yeah, I *love* working with multiple languages and keeping dependencies bug-free!"

Because of that, the realisation was made: why not work with a programming language that has a working
C/C++ drop-in compiler so you simplify having to build `.dll` binaries, e.g. EFM or systems, and then transpiled
your code into Lua? That is what orbit focuses on.

## Motive
By utilising *[ziglua](https://github.com/natecraddock/ziglua)* and building an AST-based compiler, orbit could be used as both:

<ul>a.) a bridge layer, interoperability between both Zig and Lua;</ul>
<ul>b.) a drop-in transpilation & compilation solution for managing C++ and Lua.</ul>

orbit should allow you to take the following pseudocode and achieve a pragmatic Lua equivalent:

**main.zig**
```zig
const std = @import("std");
const orbit = @import("orbit");

// just a jolly good 'ol normal function
pub fn foo() ?u8 {
  const bar: u8 = 1;
  if (bar >= 1)
    return bar;
  return null;
}

// let's say we're working with an external lib, e.g. libc & C++ interop and we want to convert headers
pub extern "c" fn @"fstat$INODE64"(fd: std.c.fd_t, buf: *std.c.Stat) c_int;

// the user facing code may have different error types presented
pub fn main() anyerror!void {
  var lvm: orbit.Lvm = try orbit.createLvm(.{}); // a LOT could happen here, comes down to OS & I/O conditions
  defer lvm.deinit();

  try lvm.build(foo); // comptime type reflection w/ generic, may return an error
  try lvm.build(@"fstat$INODE64"); // custom identifiers work because Zig recognises it during comptime

  // iteration is a feasible alternate solution, but it's pretty stupid if you think about it
  // so instead of iterating, we should also be capable of writing to the LVM directly!

  // this approach can possibly present many errors, or optional data when present.
  // while contrary to the naming of the function, this actively interferes with the transpilation process
  _ = try lvm.parse(
    \\pub fn baz() bool {
    \\  const bax: bool = false;
    \\  return bax;
    \\}
  );

  // finally, we should be able to try passing Lua code directly into our LVM
  // lacking this capability would serve as a detriment to interoperability
  _ = try lvm.lua(
    \\function luaFoo()
    \\  local luaBar = true
    \\  return luaBar
    \\end
  );
}
```

**generated.lua**
```lua
function foo()
  bar = 1
  if bar >= 1 then
    return bar
  end
  return nil
end

-- Lua only accepts alphanumeric with underscore naming with functions, the best workaround is via.
-- table key. all extern will always be accessible in a global variable as such. be mindful that
-- declarations are created separate, referencing or caching may be necessary
extern["fstat$INODE64"] = function() end

function baz()
  bax = false
  return bax
end

function luaFoo()
  local luaBar = true
  return luaBar
end
```

## Implementation
The most logical implementation would be building a [source-to-source compiler](https://en.wikipedia.org/wiki/Source-to-source_compiler), otherwise known as a transpiler.
The type of transpiler we're wanting to build would be considered a "micro"-transpiler – in the sense that
we're only attempting to convert *select* Zig code behaviour over into Lua. Some things, like packed structs,
union enums, and recursion are not meant to make it into the LVM, as this behaviour acts erratically different
in Zig than intended in Lua.

Building a microtranspiler means we need to consider the following steps in chronological order:

1. Intermediate Representation (IR) - we have to cut our food into chewable pieces before we can swallow, right?
    - ZIR - Zig IR, we perform syntactic lowering on the code (erase types, eliminate repetitions, etc.) and convert it into an AST structure 
    - OIR - Orbit IR, we start semantic analysis on the AST structure and prepare it for LVM codegen
    - LIR - Lua IR, we take the instructions and convert it into bytecode for the LVM to interpret
2. Language bindings – we can use ziglua for this, but the *real* caveat is working in Lua. Any Lua file wanting to work with orbit needs to be a Lua C file and `require` in a normal Lua. (Module management?)
3. Command Line Interpreter (CLI) – it's going to simplify peoples' lives a lot more if you can use it like a CLI, e.g.
    - `$ orbit build -F main.zig`
    - `$ orbit build --string="std.debug.print(\"hello world!\", .{});"`
