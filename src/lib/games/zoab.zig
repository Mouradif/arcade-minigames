const ZoabGame = @This();

const std = @import("std");
const rl = @import("raylib");

const Constants = @import("../constants.zig");
const GameContext = @import("../game_context.zig");
const Utils = @import("../utils.zig");
const EndingScreen = @import("../screens/ending.zig");

const Direction = enum {
    up,
    down,
    left,
    right,
};

const PANEL_X: i32 = @divTrunc(Constants.WIDTH, 2) - @divTrunc(Constants.SCREEN_HEIGHT, 2);
const PANEL_Y = Constants.SCREEN_Y_PADDING;
const PANEL_SIZE = Constants.SCREEN_HEIGHT;

const TILE_PADDING: i32 = 4;
const TILE_SIZE = @divTrunc(PANEL_SIZE - TILE_PADDING, 4) - TILE_PADDING;

const tile_font_size = 42;

const TILE_COLORS = [_]rl.Color{
    rl.Color.white,         // 0
    rl.Color.pink,          // 2
    rl.Color.red,           // 4
    rl.Color.yellow,        // 8
    rl.Color.beige,         // 16
    rl.Color.orange,        // 32
    rl.Color.light_gray,    // 64
    rl.Color.sky_blue,      // 128
    rl.Color.lime,          // 256
    rl.Color.ray_white,     // 512
    rl.Color.gold,          // 1024
    rl.Color.pink,          // 2048
    rl.Color.ray_white      // 4096
};

context: *GameContext,
grid: [4][4]u8,
cooldown: usize = 0,
score: i32 = 0,

pub fn init(self: *ZoabGame, context: *GameContext) void {
    self.context = context;
    self.cooldown = 0;
    self.score = 0;
    for (0..4) |j| {
        for (0..4) |i| {
            self.grid[j][i] = 0;
        }
    }
    self.randomlyAppear();
    self.randomlyAppear();
}

pub fn deinit(self: *ZoabGame) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *ZoabGame) void {
    self.draw();
    if (self.context.isRunning()) {
        self.handleInput();
    }
}

fn randomlyAppear(self: *ZoabGame) void {
    const n: i32 = rl.getRandomValue(1, 2);
    var empty_spots: [16]*u8 = undefined;
    const empty_spots_len = self.getEmptySpots(&empty_spots);
    if (empty_spots_len == 0) return;

    const index: usize = @intCast(rl.getRandomValue(0, @intCast(empty_spots_len - 1)));
    empty_spots[index].* = @intCast(n);
}

fn getEmptySpots(self: *ZoabGame, list: []*u8) usize {
    var n: usize = 0;
    for (0..4) |j| {
        for (0..4) |i| {
            if (self.grid[j][i] != 0) continue;
            list[n] = &self.grid[j][i];
            n += 1;
        }
    }
    return n;
}

fn move(self: *ZoabGame, dir: Direction) void {
    self.cooldown = 5;
    var squares: [4][4]*u8 = undefined;
    var anything_moved = false;
    for (0..4) |j| {
        for (0..4) |i| {
            squares[j][i] = switch (dir) {
                .up => &self.grid[3 - i][j],
                .down => &self.grid[i][j],
                .left => &self.grid[j][3 - i],
                .right => &self.grid[j][i],
            };
        }
    }
    for (0..4) |j| {
        while (true) {
            var just_moved = false;
            for (0..3) |i| {
                if (squares[j][4 - i - 1].* == 0 and squares[j][4 - i - 2].* != 0) {
                    squares[j][4 - i - 1].* = squares[j][4 - i - 2].*;
                    squares[j][4 - i - 2].* = 0;
                    anything_moved = true;
                    just_moved = true;
                }
            }
            if (!just_moved) break;
        }
        var just_merged = false;
        for (0..3) |i| {
            if (squares[j][4 - i - 1].* > 0 and squares[j][4 - i - 1].* == squares[j][4 - i - 2].* and !just_merged) {
                squares[j][4 - i - 1].* += 1;
                squares[j][4 - i - 2].* = 0;
                self.score += std.math.pow(i32, 2, @intCast(squares[j][4 - i - 1].*));
                just_merged = true;
                anything_moved = true;
                continue;
            }
            just_merged = false;
        }
    }
    if (anything_moved) {
        self.randomlyAppear();
    }
    self.checkGameOver();
}

fn draw(self: ZoabGame) void {
    rl.drawRectangle(PANEL_X, PANEL_Y, PANEL_SIZE, PANEL_SIZE, rl.Color.black);
    for (0..4) |j| {
        for (0..4) |i| {
            const x: f32 = @floatFromInt(PANEL_X + i * TILE_SIZE + i * TILE_PADDING + TILE_PADDING);
            const y: f32 = @floatFromInt(PANEL_Y + j * TILE_SIZE + j * TILE_PADDING + TILE_PADDING);
            const size: f32 = @floatFromInt(TILE_SIZE);
            const rect = rl.Rectangle.init(x, y, size, size);
            const tile_value = self.grid[j][i];
            rl.drawRectangleRounded(rect, 0.1, 15, TILE_COLORS[tile_value]);
            if (tile_value > 0) {
                var buffer: [10]u8 = undefined;
                const buffer_ptr = @as([:0]u8, @ptrCast(&buffer));
                const ascii_tile_label = Utils.itoa(usize, buffer_ptr, std.math.pow(usize, 2, tile_value));
                const text_width: f32 = @floatFromInt(rl.measureText(ascii_tile_label, tile_font_size));
                const text_x: i32 = @intFromFloat(x + @divTrunc(TILE_SIZE, 2) - @divTrunc(text_width, 2));
                const text_y: i32 = @intFromFloat(y + @divTrunc(TILE_SIZE, 2) - @divTrunc(tile_font_size, 2));
                rl.drawText(ascii_tile_label, text_x, text_y, tile_font_size, rl.Color.black);
            }

        }
    }
}

fn handleInput(self: *ZoabGame) void {
    if (self.cooldown > 0) {
        self.cooldown -= 1;
        return;
    }
    if (rl.isKeyPressed(.up) or rl.isKeyPressed(.w)) {
        return self.move(.up);
    }
    if (rl.isKeyPressed(.down) or rl.isKeyPressed(.s)) {
        return self.move(.down);
    }
    if (rl.isKeyPressed(.left) or rl.isKeyPressed(.a)) {
        return self.move(.left);
    }
    if (rl.isKeyPressed(.right) or rl.isKeyPressed(.d)) {
        return self.move(.right);
    }
}

fn checkGameOver(self: *ZoabGame) void {
    var empty_spots: [16]*u8 = undefined;
    const empty_spots_len = self.getEmptySpots(&empty_spots);
    if (empty_spots_len == 0) {
        return self.gameOver();
    }
}

fn gameOver(self: *ZoabGame) void {
    self.context.setScreen(.ending, EndingScreen, EndingScreen.Props{
        .score = self.score,
    }) catch {
        @panic("Could not change screen");
    };
}
