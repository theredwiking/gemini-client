const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");

const window = @import("window.zig");
const gemini = @import("gemini/network.zig");

const net = std.net;

const winapi = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn AttachConsole(dwProcessId: std.os.windows.DWORD) std.os.windows.BOOL;
} else struct {};

const Backend = dvui.backend;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("LEAK DETECTED");
        }
    }

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

    var buf = std.mem.zeroes([50]u8);
    var enter_pressed: bool = false;

    main_loop: while (true) {
        const nstime = win.beginWait(backend.hasEvent());
        try win.begin(nstime);

        const quit = try backend.addAllEvents(&win);
        if (quit) break :main_loop;

        _ = Backend.c.SDL_SetRenderDrawColor(backend.renderer, 255, 255, 255, 255);
        _ = Backend.c.SDL_RenderClear(backend.renderer);
        try window.textInput(&buf, &enter_pressed);
        // TODO: Change so that only request is done in here
        //       and textArea is called outside if statement
        //       and add a way to detect buf changed
        if (enter_pressed) {
            var stream = try gemini.init(allocator, &buf);
            try stream.connect();

            try stream.write(&buf);
            var response = try stream.read();
            try window.textArea(response);
            response.deinit();
            try stream.deinit();
        }

        const end_micros = try win.end(.{});

        backend.setCursor(win.cursorRequested());
        backend.textInputRect(win.textInputRequested());

        backend.renderPresent();

        const wait_event_micros = win.waitTime(end_micros, null);
        backend.waitEventTimeout(wait_event_micros);
    }
}
