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

const Orientation = enum {
    Horizontal,
    Vertical,
};

const PANEL_X: i32 = @divTrunc(Constants.WIDTH, 2) - @divTrunc(Constants.SCREEN_HEIGHT, 2);
const PANEL_Y = Constants.SCREEN_Y_PADDING;
const PANEL_SIZE = Constants.SCREEN_HEIGHT;
const ANIM_DURATION = 7;
const INPUT_COOLDOWN = 5;
const GAME_OVER_DURATION = 90;

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
grid: [4][4]u4 = .{.{0,0,0,0},.{0,0,0,0},.{0,0,0,0},.{0,0,0,0}},
next_grid: [4][4]u4 = undefined,
cooldown: usize = 0,
score: i32 = 0,
is_animating: bool = false,
game_over_timer: ?usize = null,

pub fn init(self: *ZoabGame, context: *GameContext) void {
    self.* = .{
        .context = context,
    };
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
    if (self.game_over_timer) |*timer| {
        if (timer.* == 0) return self.gameOver();
        timer.* -= 1;
    }
    self.draw();
    if (self.context.isRunning()) {
        if (self.cooldown > 0) {
            self.cooldown -= 1;
            return;
        }
        self.handleInput();
    }
}

fn randomlyAppear(self: *ZoabGame) void {
    const n: i32 = rl.getRandomValue(1, 2);
    var empty_spots: [16]*u4 = undefined;
    const empty_spots_len = self.getEmptySpots(&empty_spots);
    if (empty_spots_len == 0) return;

    const index: usize = @intCast(rl.getRandomValue(0, @intCast(empty_spots_len - 1)));
    empty_spots[index].* = @intCast(n);
}

fn getEmptySpots(self: *ZoabGame, list: []*u4) usize {
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

fn backupGrid(self: *ZoabGame) void {
    for (0..4) |j| {
        for (0..4) |i| self.next_grid[j][i] = self.grid[j][i];
    }
}

fn commitGrid(self: *ZoabGame) bool {
    var any_diff = false;
    for (0..4) |j| {
        for (0..4) |i| {
            if (self.grid[j][i] == self.next_grid[j][i]) continue;
            self.grid[j][i] = self.next_grid[j][i];
            any_diff = true;
        }
    }
    return any_diff;
}

inline fn cellPtr(self: *ZoabGame, dir: Direction, j: usize, i: usize) *u4 {
    return switch (dir) {
        .left => &self.next_grid[j][i],
        .right => &self.next_grid[j][3 - i],
        .up => &self.next_grid[i][j],
        .down => &self.next_grid[3 - i][j],
    };
}

fn squeezeMerge(line: *[4]*u4) i32 {
    var score: i32 = 0;
    var out: [4]u4 = .{0,0,0,0};
    var index: usize = 0;
    var pending: u4 = 0;

    for (line.*) |cell| {
        const x = cell.*;
        if (x == 0) continue;

        if (pending == 0) {
            pending = x;
        } else if (pending == x) {
            const merged: u4 = pending + 1;
            out[index] = merged;
            index += 1;
            score += @as(i32, 1) << @as(u5, @intCast(merged));
            pending = 0;
        } else {
            out[index] = pending;
            index += 1;
            pending = x;
        }
    }
    if (pending != 0) {
        out[index] = pending;
    }
    for (0..4) |i| line.*[i].* = out[i];

    return score;
}

fn move(self: *ZoabGame, dir: Direction) void {
    self.cooldown = INPUT_COOLDOWN;
    var squares: [4][4]*u4 = undefined;

    self.backupGrid();
    for (0..4) |j| {
        for (0..4) |i| squares[j][i] = self.cellPtr(dir, j, i);
    }
    for (0..4) |i| {
        self.score += squeezeMerge(&squares[i]);
    }
    if (self.commitGrid()) {
        self.randomlyAppear();
    }
    if (!self.canMove()) {
        self.game_over_timer = GAME_OVER_DURATION;
    }
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
            if (tile_value == 0) continue;

            var buffer: [10]u8 = undefined;
            const buffer_ptr = @as([:0]u8, @ptrCast(&buffer));
            const ascii_tile_label = Utils.itoa(usize, buffer_ptr, @shlExact(@as(usize, 1), tile_value));
            const text_width: f32 = @floatFromInt(rl.measureText(ascii_tile_label, tile_font_size));
            const text_x: i32 = @intFromFloat(x + @divTrunc(TILE_SIZE, 2) - @divTrunc(text_width, 2));
            const text_y: i32 = @intFromFloat(y + @divTrunc(TILE_SIZE, 2) - @divTrunc(tile_font_size, 2));
            rl.drawText(ascii_tile_label, text_x, text_y, tile_font_size, rl.Color.black);
        }
    }
}

fn handleInput(self: *ZoabGame) void {
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

fn canMove(self: *ZoabGame) bool {
    var empty_spots: [16]*u4 = undefined;
    const empty_spots_len = self.getEmptySpots(&empty_spots);
    if (empty_spots_len > 0) {
        return true;
    }
    for (1..4) |j| {
        for (1..4) |i| {
            const c = self.grid[j][i];
            if (c == self.grid[j][i - 1] or c == self.grid[j - 1][i]) return true;
        }
    }
    return false;
}

fn gameOver(self: *ZoabGame) void {
    self.context.setScreen(.ending, EndingScreen, EndingScreen.Props{
        .score = self.score,
    }) catch {
        @panic("Could not change screen");
    };
}
