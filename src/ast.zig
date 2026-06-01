const std = @import("std");
const lexer = @import("lexer.zig");

pub const ExprKind = enum { Identifier, IntLiteral, BoolLiteral, NullLiteral, StringLiteral, Binary };

pub const Expr = struct {
    kind: ExprKind,
    identifier: []const u8,
    int_value: u64,
    bool_value: bool,
    string_value: []const u8,
    left: ?*Expr,
    right: ?*Expr,
    op: lexer.TokenKind,
};

pub const StmtKind = enum { VarDecl, ConstDecl, Assign, Return, If, Block, ExprStmt, RawLua };

pub const Parameter = struct {
    name: []const u8,
    type_name: []const u8,
};

pub const Stmt = struct {
    kind: StmtKind,
    name: []const u8,
    value: ?*Expr,
    is_const: bool,
    condition: ?*Expr,
    then_body: []Stmt,
    else_body: []Stmt,
    expr: ?*Expr,
};

pub const DeclKind = enum { Function, Extern };

pub const Decl = struct {
    kind: DeclKind,
    name: []const u8,
    external_name: []const u8,
    params: []Parameter,
    body: []Stmt,
};

pub const Program = struct {
    decls: std.ArrayList(Decl),
};
