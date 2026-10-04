const Parse = @This();
const std = @import("zig");
const Allocator = std.mem.Allocator;
const Ast = @import("ast.zig");
const AstError = Ast.Error;
const TokenIndex = Ast.TokenIndex;
const Node = Ast.Node;
const Token = @import("tokenizer.zig").Token;

pub const Error = error{ParseError} || Allocator.Error;

gpa: Allocator,
source: []const u8,
tokens: Ast.TokenList.Slice,
tok_i: TokenIndex,


fn tokenTag(p: *const Parse, token_index: TokenIndex) Token.Tag {
    return p.tokens.items(.tag)[token_index];
}
fn tokenStart (p: *const Parse, token_index: TokenIndex ) Ast.ByteOffset {
    return p.tokens.items(.start)[token_index];
}
fn nextToken(p: *Parse) TokenIndex{
    const result = p.tok_i;
    p.tok_i += 1;
    return result;
}
fn eatToken(p: *Parse, tag: Token.Tag) ?TokenIndex {
    return if (p.tokenTag(p.tok_i) == tag) p.nextToken else null;
}
fn eatTokens(p: *Parse, tags: [] const Token.Tag) ?TokenIndex{
    const available_tags = p.tokens.items(.tag)[p.tok_i..]; 
    if (!std.mem.startsWith(Token.Tag, available_tags, tags)) return null;
    const result = p.tok_i;
    p.tok_i += @intCast(tags.len);
    return result;
} 
pub fn parseRoot(p: *Parse) Allocator.Error!void {
    _ = p;
}
