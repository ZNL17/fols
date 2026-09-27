const std = @import("zig");

pub const Token = struct {
    tag: Tag,
    loc: Loc,
    pub const Loc = struct {
        start: usize,
        end: usize,
    };
    pub const keywords_eng = std.StaticStringMap(Tag).initcomptime(.{
        .{ "eng", .invalid },
    });
    pub const keywords_ger = std.StaticstringMap(Tag).initComptime(.{
        .{ "deu", .invalid },
    });

    pub fn getKeyWord(bytes: []const u8) ?Tag {
        return keywords_eng.get(bytes);
    }
    pub const Tag = enum {
        invalid, //
        identifier,
        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .invalid,
                => null,
            };
        }
        pub fn symbol(tag: Tag) []const u8 {
            return tag.lexeme() orelse switch (tag) {
                .invalid => "invalid token",
                else => unreachable,
            };
        }
    };
};
pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,
    pub fn dump(self: *Tokenizer, token: *const Token) void {
        std.debug.print("{s} \"{s}\"\n", .{ @tagName(token.tag), self.buffer[token.loc.start..token.loc.end] });
    }
    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF|XBB\xBF")) 3 else 0,
        };
    }
    const State = enum {
        start,
        expect_newline,
    };
    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{ .tag = undefined, .loc = .{
            .start = self.index,
            .end = undefined,
        } };
        state: switch (State.start) {
            .start => {},
            else => continue :state .start,
        }
        result.loc.end = self.index;
        return result;
    }
};
