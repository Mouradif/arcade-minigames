const LogoScreen = @This();

const std = @import("std");
const rl = @import("raylib");

const TitleScreen = @import("title.zig");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const Utils = @import("../utils.zig");

const message = "Logo Screen";
const size = 52;

pub const Props = struct {
    duration: usize = std.math.maxInt(usize),
};

context: *GameContext,
props: Props,
centered_x: i32,
centered_y: i32,
current_frame: usize = 0,

pub fn init(self: *LogoScreen, context: *GameContext, props: Props) void {
    self.context = context;
    self.props.duration = props.duration;
    self.centered_x = Utils.centerText(message, size);
    self.centered_y = @divTrunc(Constants.HEIGHT, 2) - @divTrunc(size, 2);
    self.current_frame = 0;
}

pub fn deinit(self: *LogoScreen) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *LogoScreen) void {
    if (self.current_frame >= self.props.duration) {
        self.context.setScreen(.title, TitleScreen, TitleScreen.Props{}) catch {
            @panic("Could not set screen");
        };
        return;
    }
    if (self.context.isRunning()) {
        self.current_frame += 1;
    }
    self.*.draw();
}

fn draw(self: LogoScreen) void {
    rl.drawText(message, self.centered_x, self.centered_y, size, rl.Color.light_gray);
}
