const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,
    pub const Loc = struct {
        start: usize,
        end: usize,
    };
    pub const keywords = std.StaticStringMap(std.StaticStringMap(Tag)).initComptime(.{
        .{ "english" , keywords_eng},
        .{ "german", keywords_ger},
    });
    pub const keywords_eng = std.StaticStringMap(Tag).initComptime(.{
        .{ "interpreter", .keyword_interpreter },
        .{ "declaration", .keyword_declaration },
        .{ "german" , .keyword_german },
        .{ "english", .keyword_english },
        .{ "translate", .keyword_translate },
        .{ "noabbrev", .keyword_noabbrev },
    });

    pub const keywords_ger = std.StaticStringMap(Tag).initComptime(.{
        .{ "deu", .invalid },
    });
    pub var lang: std.StaticStringMap(Tag) = undefined;

    pub fn getKeyWord(bytes: []const u8) ?Tag {
        return lang.get(bytes);
    }
    pub const Tag = enum {
        invalid, //
        identifier,
        string_literal,
        eof,
        token_error,
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
                .token_error,
                .string_literal,
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
                .question_mark => "?",
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
                .quotation_mark => "\"",
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
        string_literal,
        comment_start,
        comment,
        commands,
        int,
        decimal_point,
        float,
        buffers,
        load_buffer,
        invalid,
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
            .start => switch (self.buffer[self.index]){
                0 => {
                    if (self.index == self.buffer.len){
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    } else {
                        continue :state .invalid;
                    }
                },
                ' ', '\n', '\t', '\r' =>{
                    self.index +=1;
                    result.loc.start = self.index;
                    continue :state .start; 
                },
                '"' => {
                    result.tag = .string_literal;
                    continue :state .string_literal;
                },
                '\'' => {
                    result.tag = .apostrophe;
                    self.index += 1;
                },
                'a'...'z', 'A'...'Z' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '.' => {
                    self.index += 1;
                    switch (self.buffer[self.index]){
                        '.' => {
                            continue :state .comment_start;
                        },
                        'a'...'z', 'A'...'Z' => {
                            continue :state .commands;
                        },
                        else => {
                            result.tag = .period;
                            self.index += 1;
                        }
                    }
                },
                '|' => {
                    result.tag = .pipe;
                    self.index += 1;
                },
                '+' => {
                    result.tag = .plus;
                    self.index += 1;
                },
                '-' => {
                    result.tag = .minus;
                    self.index += 1;
                },
                '/' => {
                    result.tag = .slash;
                    self.index += 1;
                },
                '\\' => {
                    result.tag = .backslash;
                    self.index += 1;
                },
                '=' => {
                    result.tag = .equal;
                    self.index += 1;
                },
                '_' => {
                    result.tag = .underscore;
                    self.index += 1;
                },
                '?' => {
                    result.tag = .question_mark;
                    self.index += 1;
                },
                '%' => {
                    result.tag = .percent;
                    self.index += 1;
                },
                '&' => {
                    result.tag = .ampersand;
                    self.index += 1;
                },
                '(' => {
                    result.tag = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .r_paren;
                    self.index += 1;
                },
                '[' => {
                    result.tag = .l_bracket;
                    self.index += 1;
                },
                ']' => {
                    result.tag = .r_bracket;
                    self.index += 1;
                },
                '<' => {
                    result.tag = .angle_brackets_left;
                    self.index += 1;
                },
                '>' => {
                    result.tag = .angle_brackets_right;
                    self.index += 1;
                },
                ',' => {
                    result.tag = .comma;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                ':' => {
                    result.tag = .colon;
                    self.index += 1;
                },
                '^' => {
                    result.tag = .caret;
                    self.index += 1;
                },
                '~' => {
                    result.tag = .tilde;
                    self.index += 1;
                },
                '@' => {
                    result.tag = .commercial_at;
                    self.index += 1;
                },
                '`' => {
                    result.tag = .backtick;
                    self.index += 1;
                },
                '!' => {
                    result.tag = .bang;
                    self.index += 1;
                },
                '#' => {
                    result.tag = .hashtag;
                    self.index += 1;
                },
                '$' => {
                    result.tag = .dollor_sign;
                    self.index += 1;
                },
                '*' => {
                    result.tag = .asterisk;
                    self.index += 1;
                },
                '0'...'9' => {
                    result.tag = .number_literal;
                    self.index += 1;
                    continue :state .int;
                },
                else => continue :state .invalid, 

            },
            .expect_newline => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    0 => {
                        if (self.index == self.buffer.len){
                            result.tag = .invalid;
                        } else {
                            continue :state .invalid;
                        }
                    },
                    '\n' =>{
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .invalid;
                    },
                    else => continue :state .invalid,
                }
            },
            .invalid => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    0 => if (self.index == self.buffer.len){
                        result.tag =.invalid;
                    } else {
                        continue :state .invalid; 
                    },
                    '\n' => result.tag = .invalid,
                    else => continue :state .invalid,
                }
            },
            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    'a'...'z', 'A'...'Z', '0'...'9' => continue :state .identifier,
                    '|' => {
                        if ((self.index - result.loc.start) == 1){
                            continue :state .buffers;
                        }
                    },
                    else => {
                        //should commands be keywords or builtins
                        //const ident = self.buffer[result.loc.start..self.index];
                        //if (Token.getKeyWord(ident))|tag|{
                        //    result.tag = tag;
                        //}
                    },
                }
            },
            .commands => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    'a'...'z','A'...'Z' => continue :state .commands,
                    else => {},
                }
            },
            .comment_start => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    0 => {
                        if (self.index != self.buffer.len){
                            continue :state .invalid;
                        } else return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    },
                    '!' => {
                        result.tag = .keyword_interpreter_line;
                        self.index += 1;
                    },
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    '\r' => continue :state .expect_newline,
                    0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f =>{
                        continue :state .invalid;
                    },
                    else => continue :state .comment,
                }
            },
            .comment => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    0 => {
                        if (self.index != self.buffer.len){
                            continue :state .invalid;
                        } else return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    },
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    '\r' => continue :state .expect_newline,
                    0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f =>{
                        continue :state .invalid;
                    },
                    else => continue :state .comment,
                }
            },
            .int => switch (self.buffer[self.index]){
                '.',',' => continue :state .decimal_point,
                '0'...'9' => {
                    self.index += 1;
                    continue :state .int;
                },
                '|' => {
                    if ((self.index - result.loc.start) == 1) {
                        result.tag = .load_buffer;
                        self.index += 1;
                    }
                },
                else => {},
            },
            .decimal_point => {
                self.index += 1;
                switch (self.buffer[self.index]){
                    '0'...'9' => {
                        self.index += 1;
                        continue :state .float;
                    },
                    else => self.index -= 1,
                }
            },
            .float => switch(self.buffer[self.index]){
                '0'...'9' => {
                    self.index += 1;
                    continue :state .float;
                },
                else => {},
            },
            .buffers => {
                switch(self.buffer[self.index-1]){
                    'U','u' => result.tag = .user_buffer,
                    'H','h' => result.tag = .select_buffer,
                    'M','m' => result.tag = .screen_buffer,
                    'F','f' => result.tag = .function_buffer,
                    'G','g' => result.tag = .global_buffer,
                    'A','a' => result.tag = .parent_screen_buffer,
                    'P','p' => result.tag = .print_buffer,
                    'D','d' => result.tag = .add_buffer,
                    'E','e' => result.tag = .environment_buffer,
                    'T','t' => result.tag = .text_buffer, 
                    'S','s' => result.tag = .characteristics_bar_buffer, 
                    'L','l' => result.tag = .select_bar_buffer,
                    else => result.tag = .token_error,
                }
                self.index += 1;
            },
            else => continue :state .start,
        }
        result.loc.end = self.index;
        return result;
    }
};
