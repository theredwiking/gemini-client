const tokenizer = @import("tokenizer.zig");
const network = @import("network.zig");

// Functions
pub const init = network.init;
pub const tokenize = tokenizer.tokenize;

// Structs
pub const Stream = network.Stream;
pub const Token = tokenizer.Token;
