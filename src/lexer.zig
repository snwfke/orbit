const std = @import("std");

pub const TokenKind = enum {
    EOF,
    Identifier,
    IntLiteral,
    StringLiteral,
    Pub,
    Fn,
    Const,
    Var,
    If,
    Then,
    Else,
    Return,
    Extern,
    Null,
    True,
    False,
    At,
    LBrace,
    RBrace,
    LParen,
    RParen,
    Semicolon,
    Colon,
    Comma,
    Dot,
    Eq,
    EqEq,
    NotEq,
    Gt,
    Lt,
    GtEq,
    LtEq,
    Plus,
    Minus,
    Star,
    Slash,
};

pub const Token = struct {
    kind: TokenKind,
    text: []const u8,
};

pub fn lex(allocator: *const std.mem.Allocator, source: []const u8) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator.*);
    var i: usize = 0;
    while (i < source.len) : (i += 1) {
        const c = source[i];
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r') continue;
        if (c == '/') {
            if (i + 1 < source.len and source[i + 1] == '/') {
                while (i < source.len and source[i] != '\n') : (i += 1) {}
                continue;
            }
            try tokens.append(Token{ .kind = .Slash, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '{') {
            try tokens.append(Token{ .kind = .LBrace, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '}') {
            try tokens.append(Token{ .kind = .RBrace, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '(') {
            try tokens.append(Token{ .kind = .LParen, .text = source[i .. i + 1] });
            continue;
        }
        if (c == ')') {
            try tokens.append(Token{ .kind = .RParen, .text = source[i .. i + 1] });
            continue;
        }
        if (c == ';') {
            try tokens.append(Token{ .kind = .Semicolon, .text = source[i .. i + 1] });
            continue;
        }
        if (c == ':') {
            try tokens.append(Token{ .kind = .Colon, .text = source[i .. i + 1] });
            continue;
        }
        if (c == ',') {
            try tokens.append(Token{ .kind = .Comma, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '.') {
            try tokens.append(Token{ .kind = .Dot, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '@') {
            try tokens.append(Token{ .kind = .At, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '+') {
            try tokens.append(Token{ .kind = .Plus, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '-') {
            if (i + 1 < source.len and source[i + 1] == '>') {
                try tokens.append(Token{ .kind = .Eq, .text = source[i .. i + 2] });
                i += 1;
                continue;
            }
            try tokens.append(Token{ .kind = .Minus, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '*') {
            try tokens.append(Token{ .kind = .Star, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '=') {
            if (i + 1 < source.len and source[i + 1] == '=') {
                try tokens.append(Token{ .kind = .EqEq, .text = source[i .. i + 2] });
                i += 1;
                continue;
            }
            try tokens.append(Token{ .kind = .Eq, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '!') {
            if (i + 1 < source.len and source[i + 1] == '=') {
                try tokens.append(Token{ .kind = .NotEq, .text = source[i .. i + 2] });
                i += 1;
                continue;
            }
        }
        if (c == '>') {
            if (i + 1 < source.len and source[i + 1] == '=') {
                try tokens.append(Token{ .kind = .GtEq, .text = source[i .. i + 2] });
                i += 1;
                continue;
            }
            try tokens.append(Token{ .kind = .Gt, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '<') {
            if (i + 1 < source.len and source[i + 1] == '=') {
                try tokens.append(Token{ .kind = .LtEq, .text = source[i .. i + 2] });
                i += 1;
                continue;
            }
            try tokens.append(Token{ .kind = .Lt, .text = source[i .. i + 1] });
            continue;
        }
        if (c == '"') {
            const start = i + 1;
            while (i + 1 < source.len and source[i + 1] != '"') : (i += 1) {}
            if (i + 1 >= source.len) return Error.UnterminatedString;
            const text = source[start .. i + 1];
            try tokens.append(Token{ .kind = .StringLiteral, .text = text });
            i += 1;
            continue;
        }
        if (((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z')) or c == '_') {
            const start = i;
            while (i + 1 < source.len) {
                const next = source[i + 1];
                if (((next >= 'A' and next <= 'Z') or (next >= 'a' and next <= 'z') or (next >= '0' and next <= '9')) or next == '_' or next == '$') {
                    i += 1;
                    continue;
                }
                break;
            }
            const text = source[start .. i + 1];
            const kind = keywordKind(text);
            try tokens.append(Token{ .kind = kind, .text = text });
            continue;
        }
        if (c >= '0' and c <= '9') {
            const start = i;
            while (i + 1 < source.len and (source[i + 1] >= '0' and source[i + 1] <= '9')) : (i += 1) {}
            const text = source[start .. i + 1];
            try tokens.append(Token{ .kind = .IntLiteral, .text = text });
            continue;
        }

        return Error.InvalidCharacter;
    }

    try tokens.append(Token{ .kind = .EOF, .text = source[source.len..source.len] });
    return tokens.toOwnedSlice();
}

fn keywordKind(text: []const u8) TokenKind {
    if (std.mem.eql(u8, text, "pub")) return .Pub;
    if (std.mem.eql(u8, text, "fn")) return .Fn;
    if (std.mem.eql(u8, text, "const")) return .Const;
    if (std.mem.eql(u8, text, "var")) return .Var;
    if (std.mem.eql(u8, text, "if")) return .If;
    if (std.mem.eql(u8, text, "then")) return .Then;
    if (std.mem.eql(u8, text, "else")) return .Else;
    if (std.mem.eql(u8, text, "return")) return .Return;
    if (std.mem.eql(u8, text, "extern")) return .Extern;
    if (std.mem.eql(u8, text, "null")) return .Null;
    if (std.mem.eql(u8, text, "true")) return .True;
    if (std.mem.eql(u8, text, "false")) return .False;
    return .Identifier;
}

pub fn freeTokens(allocator: *const std.mem.Allocator, tokens: []Token) void {
    allocator.*.free(tokens);
}

pub const Error = error{ InvalidCharacter, UnterminatedString };
