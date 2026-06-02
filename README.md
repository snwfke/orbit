<h1>
    <img width="32" height="32" src="https://github.com/user-attachments/assets/5ebc7f8d-f3f5-4aef-ba7f-9234a62c18d3" />
    orbit
    <!-- <img src="https://github.com/snwfke/zorm/actions/workflows/zig_build.yaml/badge.svg?branch=main" /> -->
    <img src="https://img.shields.io/badge/zig-0.14.0-orange" />
    <img src="https://img.shields.io/badge/orbit-v0.1.0--alpha-black" />
</h1>

> [!WARNING]
> This project is currently in alpha, bugs may be present when used.

orbit is a microtranspiler[^1] that generates Lua from Zig code — <i>focused on typesafe code generation</i>.

Inspired by *[ziglua](https://github.com/natecraddock/ziglua)* and *[c2z](https://github.com/lassade/c2z)*,
orbit aims to be a simple, easy-to-replicate transcompiler[^1] solution for DCS modding and universal language adoption.

[^1]: This is an alternative name to a [source-to-source compiler](https://en.wikipedia.org/wiki/Source-to-source_compiler), majorly responsible
the pragmatics in language-to-language conversion.

## Features

<img align="left" height="24" src="https://github.com/user-attachments/assets/172a4360-4e79-4592-9868-08bc2ba93896" />
<ul><ul>
    <b>Typesafe, selective transpilation.</b><br/>
    Zig is our language of choice for typesafe programming, but is only being leveraged to a certain extent.
    Because of this, orbit is philosophically built on only achieving certain Zig behaviours in Lua.<br/>
    <a href="THEORY.md">Learn more →</a>
</ul></ul>

<img align="left" height="24" src="https://github.com/user-attachments/assets/31efe4e4-ee1b-4b48-80b1-866a8fd2bd5f" />
<ul><ul>
    <b>Heap memory performant.</b><br/>
    With heavy heap allocations, you can expect a program that treats your memory like a limit,
    not a suggestion. Structs, enums, tables, variables (constant) & imperative logic are compressed into
    efficient Lua operations.
</ul></ul>

<img align="left" height="24" src="https://github.com/user-attachments/assets/87ffe949-8ab1-45bc-8b75-571112906b61" />
<ul><ul>
    <b>Scalable & modular.</b><br/>
    orbit's structure is meant to serve as a proof-of-concept and working prototype for any [insert]-to-Lua (LVM)
    programs.<br/>
    <a href="LICENSE"> Learn more →</a>
</ul></ul>

## Table of Contents

<img align="left" height="24" src="https://github.com/user-attachments/assets/dd63b994-1e6e-4c68-a3a3-0f7fc979b5ee" />
<ul><ul>
    <b>Download</b><br/>
    <ul>
        <li><a href="https://github.com/snwfke/orbit/releases">Official releases</a></li>
        <li><a href="#building">Build from source</a></li>
    </ul>
</ul></ul>

<img align="left" height="24" src="https://github.com/user-attachments/assets/31f856f6-6db4-47e6-abf3-2360e7a87600" />
<ul><ul>
    <b>Usage</b><br/>
    <ul>
        <li><a href="#getting-started">Quickstart</a></li>
    </ul>
</ul></ul>

## Roadmap

This is an non-exhaustive list of items being tracked for the orbit roadmap. You can learn more about it here: 

## Building

If you are wanting to build from source, enter the following commands into your command line:

```bash
$ git clone --recursive https://github.com/snwfke/orbit
$ cd ./orbit/
$ zig build
```

Optionally, you can skip over the `$ git clone` process and build from within the target folder.

## Getting Started

If orbit is used as a library, your `build.zig` file needs the following code:

```zig
const orbit_module = b.dependency("orbit", .{}).module("orbit");
exe.addModule("orbit", orbit_module);
```

Otherwise, orbit is intended to be used as a compiled executable:

```bash
$ cd orbit
$ zig build
$ "zig-out/orbit -F test.zig -o generated.lua"
```
