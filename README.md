<h1>
    <img src="https://github.com/user-attachments/assets/cb4b5ee0-fc95-4c27-89b6-f1d023d81c7b" />
    orbit
    <!-- <img src="https://github.com/snwfke/zorm/actions/workflows/zig_build.yaml/badge.svg?branch=main" /> -->
    <img src="https://img.shields.io/badge/zig--version-0.15.2-orange" />
</h1>

> [!WARNING]
> This project is currently in alpha, bugs may be present when used.

orbit is a microtranspiler[^1] that generates Lua from Zig code — <i>focused on typesafe code generation</i>.

Inspired by *[ziglua](https://github.com/natecraddock/ziglua)* and *[c2z](https://github.com/lassade/c2z)*,
orbit aims to be a simple, easy-to-replicate transcompiler[^1] solution for DCS modding and universal language adoption.

[^1]: This is an alternative name to a [source-to-source compiler](https://en.wikipedia.org/wiki/Source-to-source_compiler), majorly responsible
the pragmatics in language-to-language conversion.

## Features

<img align="left" src="https://github.com/user-attachments/assets/d221101a-e7a5-4de0-9ce8-265c8752a875" />
<ul><ul>
    <b>Typesafe, selective transcompilation</b><br/>
    Zig is our language of choice for typesafe programming, but is only being leveraged to a certain extent.
    Because of this, orbit is philosophically built on only achieving certain Zig behaviours in Lua.<br/>
    <a href="THEORY.md">Learn more →</a>
</ul></ul>

<img align="left" src="https://github.com/user-attachments/assets/0935fbf4-ddf4-4421-a2ac-1db48c472b03" />
<ul><ul>
    <b>Memory performant</b><br/>
    With heavy allocator usage, you can expect a program that treats your memory as a limit,
    not a suggestion. Structs, enums, tables, variables (constant) & imperative logic are compressed into
    efficient Lua operations.
</ul></ul>

<img align="left" src="https://github.com/user-attachments/assets/fce48889-d2ef-4ca3-a3af-b01a4e750847" />
<ul><ul>
    <b>Scalable & modular</b><br/>
    orbit's LVM structure is scaled by the desired behaviour and modularised in target-to-source translation,
    allowing it to be used as a cookie-cutter template for other [insert]-to-Lua (LVM) programs.<br/>
    <a href="LICENSE.md"> Learn more →</a>
</ul></ul>

## Getting started
<img align="left" src="https://github.com/user-attachments/assets/942a1fc6-5e1e-495e-87d6-0c9ecc33d277" />
<ul><ul>
    <b>Download</b><br/>
    <ul>
        <li><a href="https://github.com/snwfke/orbit/releases">Official releases</a></li>
        <li><a href="/#building">Build from source</a></li>
    </ul>
</ul></ul>

<img align="left" src="https://github.com/user-attachments/assets/be074c48-9af6-43bf-a248-81615ee29f26" />
<ul><ul>
    <b>Usage</b><br/>
    <ul>
        <li><a href="/#">Documentation</a></li>
        <li><a href="/#quickstart">Quickstart</a></li>
        <li><a href="/#">Guides</a></li>
    </ul>
</ul></ul>

### Building

If you are wanting to build from source, enter the following commands into your command line:

```bash
$ git clone --recursive https://github.com/snwfke/orbit
$ cd ./orbit/
$ zig build
```

Optionally, you can skip over the `$ git clone` process and build from within the target folder.

### Quickstart

In your `build.zig` file, declare the following code:

```zig
const orbit_module = b.dependency("orbit", .{}).module("orbit");
exe.addModule("orbit", orbit_module);
```
