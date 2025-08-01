const PauseComponent = @This();

const rl = @import("raylib");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const GameSelectionScreen = @import("../screens/game_selection.zig");

pub const Props = struct {};
const width: i32 = 500;
const height: i32 = 350;

context: *GameContext,
props: Props,
is_yes: bool = false,
x: i32,
y: i32,

pub fn init(context: *GameContext) PauseComponent {
    const x = @divTrunc(Constants.WIDTH, 2) - @divTrunc(width, 2);
    const y = @divTrunc(Constants.HEIGHT, 2) - @divTrunc(height, 2);
    return .{
        .context = context,
        .props = .{},
        .x = x,
        .y = y,
    };
}

pub fn deinit(self: *PauseComponent) void {
    _ = self;
}

pub fn tick(self: *PauseComponent) void {
    self.draw();
    if (rl.isKeyReleased(.enter)) {
        if (self.is_yes) {
            if (self.context.screen != null and self.context.screen.? == .gameplay) {
                self.context.setScreen(.game_selection, GameSelectionScreen, GameSelectionScreen.Props{}) catch {
                    @panic("Could not set screen");
                };
            } else {
                self.context.exit();
            }
        }
        self.context.toggleState();
        return;
    }
    if (self.is_yes and rl.isKeyDown(.right)) {
        self.is_yes = false;
    }
    if (!self.is_yes and rl.isKeyDown(.left)) {
        self.is_yes = true;
    }
}

fn draw(self: PauseComponent) void {
    rl.drawRectangle(0, 0, Constants.WIDTH, Constants.HEIGHT, rl.Color.init(0, 0, 0, 128));
    rl.drawRectangleLines(
        self.x - 1,
        self.y - 1,
        width + 2,
        height + 2,
        rl.Color.init(0xff, 0xff, 0xff, 0x80),
    );
    rl.drawRectangle(self.x, self.y, width, height, rl.Color.init(0, 0, 0, 128));
    rl.drawText("Exit game?", self.x + 190, self.y + 37, 25, rl.Color.white);
    const yes_color = if (self.is_yes) rl.Color.black else rl.Color.white;
    const no_color = if (self.is_yes) rl.Color.white else rl.Color.black;
    if (self.is_yes) {
        rl.drawRectangle(self.x + 100, self.y + 232, 150, 50, rl.Color.white);
    } else {
        rl.drawRectangle(self.x + 250, self.y + 232, 150, 50, rl.Color.white);
    }
    rl.drawText("Yes", self.x + 150, self.y + 245, 25, yes_color);
    rl.drawText("No", self.x + 300, self.y + 245, 25, no_color);
}
