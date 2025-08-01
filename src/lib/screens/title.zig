const TitleScreen = @This();

const rl = @import("raylib");

const GameSelectionScreen = @import("game_selection.zig");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const Utils = @import("../utils.zig");

const main_text = "Title Screen";
const main_text_size = 52;
const secondary_text = "Press [Enter] to start";
const secondary_text_size = 40;

pub const Props = struct {};

context: *GameContext,
props: Props,
main_x: i32,
main_y: i32,
secondary_x: i32,
secondary_y: i32,
ticks: usize = 0,

pub fn init(self: *TitleScreen, context: *GameContext, props: Props) void {
    self.context = context;
    self.props = props;
    self.main_x = Utils.centerText(main_text, main_text_size);
    self.main_y = @divTrunc(Constants.HEIGHT, 2) - @divTrunc(main_text_size, 2);
    self.secondary_x = Utils.centerText(secondary_text, secondary_text_size);
    self.secondary_y = Constants.HEIGHT - 100;
}

pub fn deinit(self: *TitleScreen) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *TitleScreen) void {
    self.draw();
    if (!self.context.isRunning()) {
        return;
    }
    self.ticks = @mod(self.ticks + 1, 60);
    if (rl.isKeyReleased(.enter)) {
        self.context.setScreen(.game_selection, GameSelectionScreen, GameSelectionScreen.Props{}) catch {
            @panic("Could not set screen");
        };
    }
}

fn draw(self: TitleScreen) void {
    rl.drawRectangle(15, 15, Constants.WIDTH - 30, Constants.HEIGHT - 30, rl.Color.light_gray);
    rl.drawRectangle(20, 20, Constants.WIDTH - 40, Constants.HEIGHT - 40, rl.Color.dark_brown);

    rl.drawText(main_text, self.main_x, self.main_y, main_text_size, rl.Color.white);
    if (self.ticks < 30) {
        rl.drawText(secondary_text, self.secondary_x, self.secondary_y, secondary_text_size, rl.Color.white);
    }
}
