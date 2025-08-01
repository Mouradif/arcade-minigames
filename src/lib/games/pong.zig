const PongGame = @This();

const std = @import("std");
const rl = @import("raylib");

const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const Utils = @import("../utils.zig");

const paddle_width: i32 = 1;
const paddle_height: i32 = 7;
const left_player_color = rl.Color.white;
const right_player_color = rl.Color.white;
const ball_color = rl.Color.white;
const score_font_size = 18;

const screen_origin = Utils.Vector2i32{ Constants.SCREEN_X_PADDING, Constants.SCREEN_Y_PADDING };
const tile = Utils.Vector2i32{ Constants.TILE_SIZE, Constants.TILE_SIZE };
const grid = Utils.Vector2i32{ Constants.GRID_X_COUNT, Constants.GRID_Y_COUNT };

const center = tile * @divTrunc(grid, Utils.Vector2i32{ 2, 2 });

const Ball = struct {
    pos: Utils.Vector2f32,
    force: Utils.Vector2f32,
    rotation: f32,

    pub fn applyForce(self: *Ball) void {
        self.pos += self.force;
    }

    pub fn circ(self: Ball) rl.Vector2 {
        const pos = self.pos + @as(Utils.Vector2f32, @floatFromInt(screen_origin));
        return rl.Vector2.init(pos[0], pos[1]);
    }

    pub fn draw(self: Ball) void {
        const ball = @as(Utils.Vector2i32, @intFromFloat(self.pos)) + screen_origin;
        rl.drawCircle(ball[0], ball[1], @divTrunc(Constants.TILE_SIZE, 2), ball_color);
    }

    pub fn reset(self: *Ball) void {
        self.pos = center;
        self.force[0] = if (self.force[0] < 0) -5 else 5;
    }
};

const Player = struct {
    pos: Utils.Vector2f32,
    force: f32,
    score: i32,
    color: rl.Color,

    pub fn accelerate(self: *Player, dir: f32) void {
        if (self.force == 0) {
            self.force = 0.2 * dir;
            return;
        }
        if ((self.force < 0 and dir < 0) or (self.force > 0 and dir > 0)) {
            self.force *= 1.2;
            if (self.force > 1.4) {
                self.force = 1.4;
            }
            if (self.force < -1.4) {
                self.force = -1.4;
            }
            return;
        }
        self.force += 0.5 * dir;
    }

    pub fn decelerate(self: *Player) void {
        self.force *= 0.7;
        if (self.force < 0.4) {
            self.force = 0;
        }
    }

    pub fn rect(self: Player) rl.Rectangle {
        const x: f32 = self.pos[0] * @as(f32, @floatFromInt(Constants.TILE_SIZE)) + @as(f32, @floatFromInt(Constants.SCREEN_X_PADDING));
        const y: f32 = self.pos[1] * @as(f32, @floatFromInt(Constants.TILE_SIZE)) + @as(f32, @floatFromInt(Constants.SCREEN_Y_PADDING));
        const width: f32 = @floatFromInt(Constants.TILE_SIZE * paddle_width);
        const height: f32 = @floatFromInt(Constants.TILE_SIZE * paddle_height);
        return rl.Rectangle.init(x, y, width, height);
    }

    pub fn collide(self: Player, ball: *Ball) void {
        if (rl.checkCollisionCircleRec(ball.circ(), @floatFromInt(Constants.TILE_SIZE), self.rect())) {
            ball.force[0] = -ball.force[0] * 1.04;
        }
    }

    pub fn draw(self: Player) void {
        for (0..paddle_height) |j| {
            for (0..paddle_width) |i| {
                const pixel: Utils.Vector2i32 = Utils.Vector2i32{ @intCast(i), @intCast(j) } + @as(Utils.Vector2i32, @intFromFloat(self.pos));
                Utils.drawTile(pixel, self.color);
            }
        }
    }
};

context: *GameContext,
left_player: Player,
right_player: Player,
ball: Ball,
kickof_countdown: usize,

pub fn init(self: *PongGame, context: *GameContext) void {
    self.context = context;
    self.left_player = .{
        .pos = Utils.Vector2f32{ 1, @floatFromInt(@divTrunc(Constants.GRID_Y_COUNT, 2) - 3) },
        .color = left_player_color,
        .force = 0,
        .score = 0,
    };
    self.right_player = .{
        .pos = Utils.Vector2f32{ @as(f32, @floatFromInt(Constants.GRID_X_COUNT - 2)), @floatFromInt(@divTrunc(Constants.GRID_Y_COUNT, 2) - 3) },
        .color = right_player_color,
        .force = 0,
        .score = 0,
    };
    self.ball = .{
        .pos = center,
        .force = Utils.Vector2f32{ -5, -3.5 },
        .rotation = 0,
    };
    self.kickof_countdown = 60;
}

pub fn deinit(self: *PongGame) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *PongGame) void {
    self.draw();
    if (self.context.isRunning()) {
        self.handleInput();
        if (self.kickof_countdown > 0) {
            self.kickof_countdown -= 1;
        }
        self.applyForces();
    }
}

fn applyForces(self: *PongGame) void {
    if (self.kickof_countdown == 0) {
        self.ball.applyForce();
    }
    if (self.ball.pos[0] < 0) {
        self.right_player.score += 1;
        self.ball.reset();
        self.kickof_countdown = 60;
    }
    if (self.ball.pos[0] > Constants.SCREEN_WIDTH) {
        self.left_player.score += 1;
        self.ball.reset();
        self.kickof_countdown = 60;
    }
    if (self.ball.pos[1] < 0) {
        self.ball.pos[1] = -self.ball.pos[1];
        self.ball.force[1] = -self.ball.force[1];
    }
    if (self.ball.pos[1] > Constants.SCREEN_HEIGHT) {
        self.ball.pos[1] = Constants.SCREEN_HEIGHT - self.ball.pos[1] + Constants.SCREEN_HEIGHT;
        self.ball.force[1] = -self.ball.force[1];
    }
    self.left_player.pos[1] += self.left_player.force;
    self.right_player.pos[1] += self.right_player.force;
    self.left_player.collide(&self.ball);
    self.right_player.collide(&self.ball);
    if (self.left_player.pos[1] < 0) {
        self.left_player.pos[1] = 0;
    }
    if (self.left_player.pos[1] > Constants.GRID_Y_COUNT - paddle_height) {
        self.left_player.pos[1] = Constants.GRID_Y_COUNT - paddle_height;
    }
    if (self.right_player.pos[1] < 0) {
        self.right_player.pos[1] = 0;
    }
    if (self.right_player.pos[1] > Constants.GRID_Y_COUNT - paddle_height) {
        self.right_player.pos[1] = Constants.GRID_Y_COUNT - paddle_height;
    }
}

fn handleInput(self: *PongGame) void {
    if (rl.isKeyDown(.down)) {
        self.right_player.accelerate(1);
    } else if (rl.isKeyDown(.up)) {
        self.right_player.accelerate(-1);
    } else {
        self.right_player.decelerate();
    }
    if (rl.isKeyDown(.s)) {
        self.left_player.accelerate(1);
    } else if (rl.isKeyDown(.w)) {
        self.left_player.accelerate(-1);
    } else {
        self.left_player.decelerate();
    }
}

fn draw(self: PongGame) void {
    rl.drawRectangle(
        Constants.SCREEN_X_PADDING,
        Constants.SCREEN_Y_PADDING,
        Constants.SCREEN_WIDTH,
        Constants.SCREEN_HEIGHT,
        rl.Color.black,
    );
    self.left_player.draw();
    self.right_player.draw();
    self.ball.draw();
    self.drawScore();
}

fn drawScore(self: PongGame) void {
    var left_score_buffer: [10]u8 = undefined;
    var right_score_buffer: [10]u8 = undefined;
    const left_buffer_ptr = @as([:0]u8, @ptrCast(&left_score_buffer));
    const right_buffer_ptr = @as([:0]u8, @ptrCast(&right_score_buffer));
    const left_ascii = Utils.itoa(i32, left_buffer_ptr, self.left_player.score);
    const right_ascii = Utils.itoa(i32, right_buffer_ptr, self.right_player.score);
    const right_score_size = rl.measureText(right_ascii, score_font_size);
    rl.drawText(left_ascii, Constants.SCREEN_X_PADDING + 16, 36, score_font_size, rl.Color.yellow);
    rl.drawText(right_ascii, Constants.SCREEN_X_PADDING + Constants.SCREEN_WIDTH - 16 - right_score_size, 36, score_font_size, rl.Color.yellow);
}
