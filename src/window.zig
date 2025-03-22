const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const gemini = @import("gemini/root.zig");

const winapi = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn AttachConsole(dwProcessId: std.os.windows.DWORD) std.os.windows.BOOL;
} else struct {};

const Backend = dvui.backend;

pub fn textInput(buffer: *[50]u8, enter_pressed: *bool) !void {
    var left_align = dvui.Alignment.init();
    defer left_align.deinit();

    const hbox = try dvui.box(@src(), .horizontal, .{ .color_fill = .{ .name = .fill_window } });
    defer hbox.deinit();

    try dvui.label(@src(), "Search field", .{}, .{ .gravity_y = 0.5 });

    try left_align.spacer(@src(), 0);

    var txtin = try dvui.textEntry(@src(), .{ .text = .{ .buffer = buffer } }, .{ .max_size_content = dvui.Options.sizeM(20, 0) });
    if (txtin.enter_pressed) enter_pressed.* = true;
    txtin.deinit();
}

pub fn textArea(buf: std.ArrayList(gemini.Token)) !void {
    const scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .name = .fill_window } });
    defer scroll.deinit();

    const tl = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal });
    for (buf.items) |token| {
        switch (token.type) {
            .TextLine => {
                try tl.addText(token.line, .{});
            },
            .HeadingLine => {
                try tl.addText(token.line, .{ .font_style = .title });
                try tl.addText("\n", .{});
            },
            .LinkLine => {
                // TODO: Look into addTextClick
                try tl.addText(token.line, .{});
                try tl.addText("\n", .{});
            },
            else => {
                continue;
            },
        }
        try tl.addText("\n", .{});
    }
    tl.deinit();
}
