const std = @import("std");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

pub const Parser = struct {
    allocator: *const std.mem.Allocator,
    tokens: []lexer.Token,
    pos: usize,
    arena: std.heap.ArenaAllocator,
    arena_allocator: std.mem.Allocator,
};

pub fn parse(allocator: *const std.mem.Allocator, tokens: []lexer.Token) Error!ast.Program {
    var arena = std.heap.ArenaAllocator.init(allocator.*);
    var parser = Parser{
        .allocator = allocator,
        .tokens = tokens,
        .pos = 0,
        .arena = arena,
        .arena_allocator = arena.allocator(),
    };
    return try parseProgram(&parser);
}

fn parseProgram(p: *Parser) Error!ast.Program {
    var decls = std.ArrayList(ast.Decl).init(p.allocator.*);
    while (peek(p).kind != .EOF) {
        try decls.append(try parseDecl(p));
    }
    return ast.Program{ .decls = decls };
}

fn parseDecl(p: *Parser) Error!ast.Decl {
    _ = match(p, .Pub);
    const is_extern = match(p, .Extern);

    // Skip calling convention for extern declarations (e.g., extern "c")
    if (is_extern and peek(p).kind == .StringLiteral) {
        _ = next(p);
    }

    if (!match(p, .Fn)) return Error.ExpectedFn;

    var name: []const u8 = "";
    var external_name: []const u8 = "";
    if (peek(p).kind == .At) {
        _ = next(p);
        const token = try expect(p, .StringLiteral);
        external_name = token.text;
        name = sanitizeName(external_name);
    } else {
        const token = try expect(p, .Identifier);
        name = token.text;
    }

    const params = try parseParameters(p);
    _ = skipReturnType(p);

    if (match(p, .Semicolon)) {
        return ast.Decl{ .kind = .Extern, .name = name, .external_name = external_name, .params = params, .body = &.{} };
    }

    const body = try parseBlock(p);
    return ast.Decl{ .kind = .Function, .name = name, .external_name = external_name, .params = params, .body = body };
}

fn parseParameters(p: *Parser) Error![]ast.Parameter {
    _ = try expect(p, .LParen);
    var params = std.ArrayList(ast.Parameter).init(p.allocator.*);
    while (peek(p).kind != .RParen and peek(p).kind != .EOF) {
        const nameToken = try expect(p, .Identifier);
        _ = match(p, .Colon);
        while (peek(p).kind != .Comma and peek(p).kind != .RParen and peek(p).kind != .EOF) {
            _ = next(p);
        }
        try params.append(ast.Parameter{ .name = nameToken.text, .type_name = "" });
        if (!match(p, .Comma)) break;
    }
    _ = try expect(p, .RParen);
    return params.toOwnedSlice();
}

fn skipReturnType(p: *Parser) []const u8 {
    if (match(p, .Colon)) {
        const start = p.pos;
        while (peek(p).kind != .LBrace and peek(p).kind != .Semicolon and peek(p).kind != .EOF) {
            _ = next(p);
        }
        if (p.pos > start) {
            return p.tokens[start].text;
        }
    }
    return "";
}

fn parseBlock(p: *Parser) Error![]ast.Stmt {
    _ = try expect(p, .LBrace);
    var stmts = std.ArrayList(ast.Stmt).init(p.allocator.*);
    while (!match(p, .RBrace)) {
        try stmts.append(try parseStmt(p));
    }
    return stmts.toOwnedSlice();
}

fn parseStmt(p: *Parser) Error!ast.Stmt {
    if (match(p, .If)) {
        const condition = try parseExpression(p);
        _ = try expect(p, .Then);
        const then_body = try parseStmtBlockOrStmt(p);
        var else_body: []ast.Stmt = &.{};
        if (match(p, .Else)) {
            else_body = try parseStmtBlockOrStmt(p);
        }
        return ast.Stmt{ .kind = .If, .condition = condition, .then_body = then_body, .else_body = else_body, .value = null, .expr = null, .name = "", .is_const = false };
    }
    if (match(p, .Return)) {
        const expr = try parseExpression(p);
        _ = try expect(p, .Semicolon);
        return ast.Stmt{ .kind = .Return, .expr = expr, .name = "", .condition = null, .then_body = &.{}, .else_body = &.{}, .value = null, .is_const = false };
    }
    if (match(p, .Const) or match(p, .Var)) {
        const kind = if (p.tokens[p.pos - 1].kind == .Const) ast.StmtKind.ConstDecl else ast.StmtKind.VarDecl;
        const nameToken = try expect(p, .Identifier);
        _ = match(p, .Colon);
        _ = skipTypeAnnotation(p);
        _ = try expect(p, .Eq);
        const value = try parseExpression(p);
        _ = try expect(p, .Semicolon);
        return ast.Stmt{ .kind = kind, .name = nameToken.text, .value = value, .is_const = kind == .ConstDecl, .condition = null, .then_body = &.{}, .else_body = &.{}, .expr = null };
    }
    const expr = try parseExpression(p);
    if (match(p, .Eq)) {
        const value = try parseExpression(p);
        _ = try expect(p, .Semicolon);
        return ast.Stmt{ .kind = .Assign, .name = expr.identifier, .value = value, .condition = null, .then_body = &.{}, .else_body = &.{}, .expr = null, .is_const = false };
    }
    _ = try expect(p, .Semicolon);
    return ast.Stmt{ .kind = .ExprStmt, .expr = expr, .name = "", .value = null, .condition = null, .then_body = &.{}, .else_body = &.{}, .is_const = false };
}

fn parseStmtBlockOrStmt(p: *Parser) Error![]ast.Stmt {
    if (peek(p).kind == .LBrace) {
        return try parseBlock(p);
    }
    var stmts = std.ArrayList(ast.Stmt).init(p.allocator.*);
    try stmts.append(try parseStmt(p));
    return stmts.toOwnedSlice();
}

fn parseExpression(p: *Parser) Error!*ast.Expr {
    var left = try parsePrimary(p);
    while (isBinaryOperator(peek(p).kind)) {
        const op = next(p).kind;
        const right = try parsePrimary(p);
        const node = try allocExpr(p, ast.Expr{
            .kind = .Binary,
            .left = left,
            .right = right,
            .op = op,
            .identifier = "",
            .int_value = 0,
            .bool_value = false,
            .string_value = "",
        });
        left = node;
    }
    return left;
}

fn parsePrimary(p: *Parser) Error!*ast.Expr {
    const token = next(p);
    if (token.kind == .Identifier) {
        return try allocExpr(p, ast.Expr{ .kind = .Identifier, .identifier = token.text, .int_value = 0, .bool_value = false, .string_value = "", .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .IntLiteral) {
        const value = std.fmt.parseInt(u64, token.text, 10) catch return Error.UnexpectedToken;
        return try allocExpr(p, ast.Expr{ .kind = .IntLiteral, .identifier = "", .int_value = value, .bool_value = false, .string_value = "", .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .True) {
        return try allocExpr(p, ast.Expr{ .kind = .BoolLiteral, .identifier = "", .int_value = 0, .bool_value = true, .string_value = "", .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .False) {
        return try allocExpr(p, ast.Expr{ .kind = .BoolLiteral, .identifier = "", .int_value = 0, .bool_value = false, .string_value = "", .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .Null) {
        return try allocExpr(p, ast.Expr{ .kind = .NullLiteral, .identifier = "", .int_value = 0, .bool_value = false, .string_value = "", .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .StringLiteral) {
        return try allocExpr(p, ast.Expr{ .kind = .StringLiteral, .identifier = "", .int_value = 0, .bool_value = false, .string_value = token.text, .left = null, .right = null, .op = .EOF });
    } else if (token.kind == .LParen) {
        return try parseParenExpression(p);
    }
    return Error.UnexpectedToken;
}

fn parseParenExpression(p: *Parser) Error!*ast.Expr {
    const expr = try parseExpression(p);
    _ = try expect(p, .RParen);
    return expr;
}

fn allocExpr(p: *Parser, expr: ast.Expr) Error!*ast.Expr {
    const ptr = p.arena_allocator.create(ast.Expr) catch return Error.OutOfMemory;
    ptr.* = expr;
    return ptr;
}

fn skipTypeAnnotation(p: *Parser) bool {
    while (peek(p).kind != .Eq and peek(p).kind != .Semicolon and peek(p).kind != .EOF) {
        _ = next(p);
    }
    return true;
}

fn match(p: *Parser, kind: lexer.TokenKind) bool {
    if (peek(p).kind == kind) {
        _ = next(p);
        return true;
    }
    return false;
}

fn expect(p: *Parser, kind: lexer.TokenKind) !lexer.Token {
    if (peek(p).kind == kind) return next(p);
    return Error.ExpectedToken;
}

fn peek(p: *Parser) lexer.Token {
    if (p.pos >= p.tokens.len) return lexer.Token{ .kind = .EOF, .text = "" };
    return p.tokens[p.pos];
}

fn next(p: *Parser) lexer.Token {
    const token = peek(p);
    if (p.pos < p.tokens.len) p.pos += 1;
    return token;
}

fn isBinaryOperator(kind: lexer.TokenKind) bool {
    return switch (kind) {
        .EqEq, .NotEq, .Gt, .Lt, .GtEq, .LtEq, .Plus, .Minus, .Star, .Slash => true,
        else => false,
    };
}

fn sanitizeName(_input: []const u8) []const u8 {
    _ = _input;
    const buf = "__orbit_fn";
    return buf;
}

pub const Error = error{ ExpectedFn, ExpectedToken, UnexpectedToken, OutOfMemory };
