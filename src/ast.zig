const std = @import("zig");
const mem = std.mem; 
const Tokenizer = @import("tokenizer.zig");
const Token = Tokenizer.Token; 
const Ast = @This(); 
const Allocator = std.mem.Allocator;


source: [:0]const u8,
tokens: TokenList.Slice,
nodes: NodeList.Slice,
pub const ByteOffset = u32;
pub const TokenList = std.MultiArrayList(struct {
    tag: Token.Tag,
    start: ByteOffset,
});
pub const NodeList = std.MultiArrayList(Node);
pub const TokenIndex = u32;
pub const Location = struct {
    line: usize,
    column: usize,
    line_start: usize,
    line_end: usize, 
};
pub const Span = struct {
    start: u32,
    end: u32,
    main: u32,
};
pub fn deinit(tree: *Ast, gpa: Allocator) void {
    tree.tokens.deinit(gpa);
    tree.nodes.deinit(gpa);
    tree.* = undefined;
}
pub fn parse(gpa: Allocator, source: [:0]const u8) Allocator.Error!Ast {
    var tokens = Ast.TokenList{};
    defer tokens.deinit(gpa);
    //TODO: should do own estimations
    const estimated_token_count = source.len / 8;
    try tokens.ensureTotalCapacity(gpa, estimated_token_count);
    var tokenizer = Tokenizer.Tokenizer.init(source);
    while (true){
        const token = tokenizer.next();
        try tokens.append(gpa, .{
            .tag = token.tag,
            .start = @intCast(token.loc.start),
        });
        if (token.tag == .eof) break;
    }
    var token_slice = tokens.toOwnedSlice();
    errdefer token_slice.deinit(gpa);
    return parseTokens(gpa, source, token_slice);
}
pub fn parseTokens(gpa: Allocator, source: [:0]const u8, tokens: Ast.TokenList.Slice) Allocator.Error!Ast{
    _ = gpa;
    _ = source;
    _ = tokens;

}
pub const Error  = struct {
    tag: Tag,
    is_note: bool = false,
    token_is_prev: bool = false,
    token: TokenIndex,
    extra: union{
        none: void,
        expected_tag: Token.Tag,
        offset: usize, 
    } = .{.none = {}},
    pub const Tag = enum {
        place_holder,
    };
};
pub const ExtraIndex = enum(u32){
    _,
};
pub const Node = struct{

};
