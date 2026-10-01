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
    pub const keywords_ger = std.StaticStringMap(Tag).initComptime(.{
        .{ "deu", .invalid },
    });

    pub fn getKeyWord(bytes: []const u8) ?Tag {
        return keywords_eng.get(bytes);
    }
    pub const Tag = enum {
        invalid, //
        identifier,
        string_literal,
        eof,
        number_literal,
        new_line,
        period,
        comment,
        bang,
        pipe,
        equal,
        underscore,
        percent,
        quotation_mark,
        hashtag,
        dollor_sign,
        ampersand,
        apostrophe,
        asterisk,
        plus,
        minus,
        slash,
        backslash,
        comma,
        colon,
        semicolon,
        angle_brackets_left,
        angle_brackets_right,
        question_mark,
        commercial_at,
        caret,
        tilde,
        backtick,
        l_paren,
        r_paren,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,

        //buffers
        function_buffer,// F|
        characteristics_bar_buffer,// S|
        add_buffer,// D|
        select_buffer,// H|
        screen_buffer,// M|
        user_buffer,// U|
        global_buffer,// G|
        text_buffer,// T|
        print_buffer,// P|
        parent_screen_buffer,// A|
        environment_buffer,// E|
        load_buffer,// 0-9|
        select_bar_buffer,// L|
        // commands,
        //interpreter zeile
        keyword_interpreter_line,// ..!
        keyword_interpreter,
        keyword_declaration,
        keyword_german,
        keyword_english,
        keyword_translate,
        keyword_noabbrev,

        pub fn lexeme(tag: Tag) ?[]const u8 {
            return switch (tag) {
                .invalid,
                .identifier,
                .eof,
                .number_literal,
                .load_buffer,
                => null,
                .new_line => "\n",// TODO: should there me more whitespace shit
                .period => ".",
                .comment => "..",
                .bang => "!",
                .pipe => "|",
                .equal => "=",
                .underscore => "_",
                .percent => "%",
                .question_mark => "\"",
                .hashtag => "#",
                .dollor_sign => "$",
                .ampersand => "&",
                .apostrophe => "\'",
                .asterisk => "*",
                .plus => "+",
                .minus => "-",
                .slash => "/",
                .backslash => "\\",
                .comma => ",",
                .colon => ":",
                .semicolon => ";",
                .angle_brackets_left => "<",
                .angle_brackets_right => ">",
                .quotation_mark => "?",
                .commercial_at => "@",
                .caret => "^",
                .tilde => "~",
                .backtick => "`",
                .l_paren => "(",
                .r_paren => ")",
                .l_brace => "{",
                .r_brace => "}",
                .l_bracket => "[",
                .r_bracket => "]",

                .function_buffer => "F|",
                .characteristics_bar_buffer => "S|",
                .add_buffer => "D|",
                .select_buffer => "H|",
                .screen_buffer => "M|",
                .user_buffer => "U|",
                .global_buffer => "G|",
                .text_buffer => "T|",
                .print_buffer => "P|",
                .parent_screen_buffer => "A|",
                .environment_buffer => "E|",
                .select_bar_buffer => "L|",
                .keyword_interpreter_line => "..!",
                .keyword_interpreter => "interpreter",
                .keyword_declaration => "declaration",
                .keyword_german => "german",
                .keyword_english => "english",
                .keyword_translate => "translate",
                .keyword_noabbrev => "noabbrev",
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
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
             }
        };
        state: switch (State.start) {
            .start => {},
            else => continue :state .start,
        }
        result.loc.end = self.index;
        return result;
    }
};
