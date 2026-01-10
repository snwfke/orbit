<h1>
    <img src="https://github.com/user-attachments/assets/cb4b5ee0-fc95-4c27-89b6-f1d023d81c7b" />
    orbit
    <!-- <img src="https://github.com/snwfke/zorm/actions/workflows/zig_build.yaml/badge.svg?branch=main" /> -->
    <img src="https://img.shields.io/badge/zig--version-0.15.2-orange" />
</h1>

> [!WARNING]
> This project is currently in alpha, bugs may be present when used.

orbit is a "micro"-transpiler that generates Lua from Zig code — <i>typesafe code generation</i>.

Inspired by *[ziglua](https://github.com/natecraddock/ziglua)*, orbit aims to be a simple, easy-to-replicate
solution for DCS transpilation scripting.

## Features

<img align="left" height="44" src="" />
<ul><ul>
    <b>Low level API architecture</b><br/>
    We completely utilise Zig for everything. zorm is more than just an ORM or framework - it's an extensive set of
    datatypes that can be used across many projects, even if you're not wanting to necessarily write to a database.<br/>
    <a href="USAGE.md">Learn more →</a>
</ul></ul>

<img align="left" height="44" src="" />
<ul><ul>
    <b>Memory performant</b><br/>
    With heavy allocator usage, you can expect a program that treats your memory as a limit,
    not a suggestion. Objects come with a fixed buffer, <i>whereas</i> tables and queries expect
    you to provide your own.
</ul></ul>

<img align="left" height="44" src="" />
<ul><ul>
    <b>ACID-guaranteed transactions</b><br/>
    zorm's <code>Query</code> paradigm ensures atomicity, consistency, isolation and durability
    within each and every transaction.<br/>
    <i>This is currently work-in-progress.</i>
</ul></ul>

<img align="left" height="44" src="" />
<ul><ul>
    <b>Intuitionalistic object type theory</b><br/>
    Objects are not a real concept in Zig, technically speaking. We've developed our own type theory,
    ensuring the uniqueness of each object relative to its value, making your time building relationships
    and mappings between them easier.<br/>
    <a href="THEORY.md">Learn more →</a>
</ul></ul>

## Getting started

<img align="left" height="44" src="" />
<ul><ul>
    <b>Download</b><br/>
    <ul>
        <li><a href="https://github.com/snwfke/zorm/releases">Official releases</a></li>
        <li><a href="/#building">Build from source</a></li>
    </ul>
</ul></ul>

<img align="left" height="44" src="" />
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
