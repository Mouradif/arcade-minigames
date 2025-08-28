const std = @import("std");
const rl = @import("raylib");
const Constants = @import("lib/constants.zig");
const GameContext = @import("lib/game_context.zig");
const LogoScreen = @import("lib/screens/logo.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leaked!");
    }
    rl.setConfigFlags(.{
        .window_highdpi = true,
    });
    rl.initWindow(Constants.WIDTH, Constants.HEIGHT, "Hello Raylib");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var context: GameContext = GameContext.init(allocator);
    defer context.deinit();
    try context.setScreen(.logo, LogoScreen, LogoScreen.Props{ .duration = 30 });

    rl.setExitKey(.null);

    while (!rl.windowShouldClose() and !context.should_exit) {
        if (rl.isKeyReleased(.escape)) {
            context.toggleState();
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        context.draw();
        rl.clearBackground(rl.Color.dark_brown);
    }
}
