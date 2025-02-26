const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");

const winapi = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn AttachConsole(dwProcessId: std.os.windows.DWORD) std.os.windows.BOOL;
} else struct {};

const Backend = dvui.backend;

pub fn window(allocator: std.mem.Allocator) !void {
    if (builtin.os.tag == .windows) {
        _ = winapi.AttachConsole(0xFFFFFFFF);
    }

    std.log.info("SDL version: {}", .{Backend.getSDLVersion()});

    var backend = try Backend.initWindow(.{
        .allocator = allocator,
        .size = .{ .w = 800.0, .h = 600.0 },
        .min_size = .{ .w = 250.0, .h = 350 },
        .vsync = false,
        .title = "DVUI Testing",
    });
    defer backend.deinit();

    var win = try dvui.Window.init(@src(), allocator, backend.backend(), .{});
    defer win.deinit();

    //var buf = try allocator.alloc(u8, 50);
    //defer allocator.free(buf);
    var buf = std.mem.zeroes([50]u8);

    var enter_pressed = false;

    main_loop: while (true) {
        const nstime = win.beginWait(backend.hasEvent());
        try win.begin(nstime);

        const quit = try backend.addAllEvents(&win);
        if (quit) break :main_loop;

        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 255, 255, 255);
        _ = Backend.c.SDL_RenderClear(backend.renderer);

        try textInput(&buf, &enter_pressed);
        if (enter_pressed) {
            try textArea(buf);
        }

        const end_micros = try win.end(.{});

        backend.setCursor(win.cursorRequested());
        backend.textInputRect(win.textInputRequested());

        backend.renderPresent();

        const wait_event_micros = win.waitTime(end_micros, null);
        backend.waitEventTimeout(wait_event_micros);
    }
}

fn textInput(buffer: *[50]u8, enter_pressed: *bool) !void {
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

fn textArea(buf: [50]u8) !void {
    const scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .name = .fill_window } });
    defer scroll.deinit();

    const tl = try dvui.textLayout(@src(), .{}, .{ .expand = .horizontal });
    try tl.addText(
        \\DVUI
        \\- Testing
        \\- Maybe multiline works
        \\
    , .{});
    try tl.addText(&buf, .{});
    tl.deinit();
}
