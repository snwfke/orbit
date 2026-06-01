const std = @import("std");
const ast = @import("ast.zig");

pub fn generate(allocator: *const std.mem.Allocator, program: ast.Program) ![]const u8 {
    var out = std.ArrayList(u8).init(allocator.*);
    const writer = out.writer();

    var has_extern = false;
    for (program.decls.items) |decl| {
        if (decl.kind == .Extern) {
            has_extern = true;
        }
    }
    if (!has_extern) {
        try writer.writeAll("extern = {}\n\n");
    }

    for (program.decls.items) |decl| {
        try writeDecl(writer, decl);
        try writer.writeAll("\n");
    }

    return try out.toOwnedSlice();
}

fn writeDecl(writer: anytype, decl: ast.Decl) !void {
    switch (decl.kind) {
        .Extern => {
            const key = if (decl.external_name.len != 0) decl.external_name else decl.name;
            try std.fmt.format(writer, "extern[\"{s}\"] = function() end\n", .{key});
        },
        .Function => {
            try std.fmt.format(writer, "function {s}()\n", .{decl.name});
            for (decl.body) |stmt| {
                try writeStmt(writer, stmt, 2);
            }
            try writer.writeAll("end\n");
        },
    }
}

fn writeStmt(writer: anytype, stmt: ast.Stmt, indent: usize) !void {
    const indent_str = makeIndent(indent);
    switch (stmt.kind) {
        .VarDecl, .ConstDecl => {
            const keyword = if (stmt.kind == .ConstDecl) "local" else "local";
            try std.fmt.format(writer, "{s}{s} {s} = {s}\n", .{ indent_str, keyword, stmt.name, formatExpr(stmt.value.?) });
        },
        .Assign => {
            try std.fmt.format(writer, "{s}{s} = {s}\n", .{ indent_str, stmt.name, formatExpr(stmt.value.?) });
        },
        .Return => {
            const value = if (stmt.expr) |expr| if (expr.kind == .NullLiteral) "nil" else formatExpr(expr) else "nil";
            try std.fmt.format(writer, "{s}return {s}\n", .{ indent_str, value });
        },
        .If => {
            try std.fmt.format(writer, "{s}if {s} then\n", .{ indent_str, formatExpr(stmt.condition.?) });
            for (stmt.then_body) |then_stmt| try writeStmt(writer, then_stmt, indent + 2);
            if (stmt.else_body.len != 0) {
                try std.fmt.format(writer, "{s}else\n", .{indent_str});
                for (stmt.else_body) |else_stmt| try writeStmt(writer, else_stmt, indent + 2);
            }
            try std.fmt.format(writer, "{s}end\n", .{indent_str});
        },
        .ExprStmt => {
            try std.fmt.format(writer, "{s}{s}\n", .{ indent_str, formatExpr(stmt.expr.?) });
        },
        else => {
            try std.fmt.format(writer, "{s}-- unsupported statement\n", .{indent_str});
        },
    }
}

fn formatExpr(expr: *ast.Expr) []const u8 {
    return switch (expr.kind) {
        .Identifier => expr.identifier,
        .IntLiteral => std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{expr.int_value}) catch "0",
        .BoolLiteral => if (expr.bool_value) "true" else "false",
        .NullLiteral => "nil",
        .StringLiteral => expr.string_value,
        .Binary => {
            const left = formatExpr(expr.left.?);
            const right = formatExpr(expr.right.?);
            const op = switch (expr.op) {
                .EqEq => "==",
                .NotEq => "~=",
                .Gt => ">",
                .Lt => "<",
                .GtEq => ">=",
                .LtEq => "<=",
                .Plus => "+",
                .Minus => "-",
                .Star => "*",
                .Slash => "/",
                else => "",
            };
            return std.fmt.allocPrint(std.heap.page_allocator, "{s} {s} {s}", .{ left, op, right }) catch "";
        },
    };
}

fn makeIndent(count: usize) []const u8 {
    const indent = "                                                                        ";
    if (count <= indent.len) return indent[0..count];
    return indent[0..indent.len];
}
