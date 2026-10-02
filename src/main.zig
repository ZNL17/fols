const std = @import("std");
const Io = std.Io;
const Dir = Io.Dir;

const Tok = @import("tokenizer.zig");
const Token = Tok.Token;
pub fn main(init: std.process.Init) !void {

    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) return;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;
    if (args.len == 3 and std.mem.eql(u8,  "-d",args[1])){
        try parseFiles(arena, io, args[2],stdout_writer);
        return;
    }
    for (args[1..])|arg|{
        try parseFile( arena,io, arg, stdout_writer);
    }
    try stdout_writer.flush(); // Don't forget to flush!
}
pub fn parseFiles(alloc: std.mem.Allocator, io: std.Io, file_path: [:0]const u8, writer: *std.Io.Writer)!void{
    var dir = try std.Io.Dir.cwd().openDir(io, file_path, .{.iterate = true});
    defer dir.close(io);
    var entries = dir.iterate();
    while (try entries.next(io)) |entry|{
        const source: [:0]const u8 = &.{ file_path, entry.name};
        try parseFile(alloc, io, source, writer);
    }
}
pub fn parseFile(alloc: std.mem.Allocator,io: std.Io,file_path: [:0]const u8, writer: *std.Io.Writer) !void{
        if (std.Io.Dir.cwd().readFileAllocOptions(io, file_path, alloc, .unlimited, .@"1", 0))|source|{
        var tokenizer = Tok.Tokenizer.init(source);
        var token: Token = .{
            .tag = .invalid,
            .loc = undefined,
        };
        while (token.tag != .eof){
            token = tokenizer.next();
            //tokenizer.dump(&token);
            try writer.print("<{s}, {s}/>\n", .{@tagName(token.tag), source[token.loc.start..token.loc.end]});
            try writer.flush();
        }
    } else |err| switch(err){
        error.FileNotFound, => {
            try writer.print("",.{});
            try writer.flush();
        },
        else => {
        },
    }
}
