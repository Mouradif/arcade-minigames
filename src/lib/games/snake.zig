const SnakeGame = @This();

const rl = @import("raylib");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const EndingScreen = @import("../screens/ending.zig");
const Utils = @import("../utils.zig");

const score_font_size = 16;

const initial_direction = Constants.DIR_RIGHT;
const initial_length = 3;

context: *GameContext,
body: [256]Utils.Vector2i32,
length: usize,
apple: Utils.Vector2i32,
direction: Utils.Vector2i32,
pending_direction: Utils.Vector2i32,
frame: usize,
score: i32,

pub fn init(self: *SnakeGame, context: *GameContext) void {
    var body: [256]Utils.Vector2i32 = undefined;
    const length = initial_length;
    const direction = initial_direction;

    body[0] = Utils.Vector2i32{ @divTrunc(Constants.GRID_X_COUNT, 2), @divTrunc(Constants.GRID_Y_COUNT, 2) };
    for (1..length) |i| {
        body[i] = body[i - 1] - direction;
    }
    const apple = Utils.randomPosition();
    self.context = context;
    self.body = body;
    self.length = length;
    self.apple = apple;
    self.direction = direction;
    self.pending_direction = direction;
    self.frame = 0;
    self.score = 0;
}

pub fn deinit(self: *SnakeGame) void {
    self.context.allocator.destroy(self);
}

pub fn gameOver(self: *SnakeGame) void {
    self.context.setScreen(.ending, EndingScreen, EndingScreen.Props{
        .score = self.score,
    }) catch {
        @panic("Could not change screen");
    };
}

pub fn tick(self: *SnakeGame) void {
    if (rl.isKeyPressed(.up) and !eqlV2(self.direction, Constants.DIR_DOWN)) {
        self.pending_direction = Constants.DIR_UP;
    } else if (rl.isKeyPressed(.down) and !eqlV2(self.direction, Constants.DIR_UP)) {
        self.pending_direction = Constants.DIR_DOWN;
    } else if (rl.isKeyPressed(.left) and !eqlV2(self.direction, Constants.DIR_RIGHT)) {
        self.pending_direction = Constants.DIR_LEFT;
    } else if (rl.isKeyPressed(.right) and !eqlV2(self.direction, Constants.DIR_LEFT)) {
        self.pending_direction = Constants.DIR_RIGHT;
    }
    self.draw();
    if (self.context.isRunning()) {
        self.frame += 2;
        if (rl.isKeyDown(.space)) {
            self.frame += 3;
        }
    }
    if (self.frame >= 9) {
        self.advance();
    }
}

fn drawScore(self: SnakeGame) void {
    var buffer: [10]u8 = undefined;
    const buffer_ptr = @as([:0]u8, @ptrCast(&buffer));
    const ascii_score = Utils.itoa(i32, buffer_ptr, self.score);
    const score_size = rl.measureText(ascii_score, score_font_size);
    rl.drawText(ascii_score, Constants.WIDTH - score_size - 20, 36, score_font_size, rl.Color.yellow);
}

fn advance(self: *SnakeGame) void {
    const ate = eqlV2(self.body[0], self.apple);
    if (ate) {
        self.score += 32;
        self.body[self.length] = self.body[self.length - 1];
        self.apple = Utils.randomPosition();
    }
    for (0..self.length - 1) |i| {
        self.body[self.length - i - 1] = self.body[self.length - i - 2];
    }
    if (ate) {
        self.length += 1;
    }
    self.direction = self.pending_direction;
    self.body[0] += self.direction;
    if (self.body[0][0] < 0 or self.body[0][1] < 0 or self.body[0][0] >= Constants.GRID_X_COUNT or self.body[0][1] >= Constants.GRID_Y_COUNT) {
        return self.gameOver();
    }
    for (1..self.length) |i| {
        if (eqlV2(self.body[0], self.body[i])) {
            return self.gameOver();
        }
    }
    self.frame = 0;
}

fn draw(self: *SnakeGame) void {
    rl.drawRectangle(
        Constants.SCREEN_X_PADDING,
        Constants.SCREEN_Y_PADDING,
        Constants.SCREEN_WIDTH,
        Constants.SCREEN_HEIGHT,
        rl.Color.black,
    );
    Utils.drawTile(self.apple, rl.Color.pink);
    for (0..self.length) |i| {
        Utils.drawTile(self.body[i], rl.Color.white);
    }
    self.drawScore();
}

fn eqlV2(a: Utils.Vector2i32, b: Utils.Vector2i32) bool {
    const eql = a == b;
    return eql[0] and eql[1];
}
