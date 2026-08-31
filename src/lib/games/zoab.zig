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
const ANIM_DURATION = 8;
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

const Animation = struct {
    dir: Direction,
    start: ?u4 = null,
    end: u4,
    value: u4,

    merged: bool,
};

context: *GameContext,
grid: [4][4]u4 = .{.{0,0,0,0},.{0,0,0,0},.{0,0,0,0},.{0,0,0,0}},
next_grid: [4][4]u4 = undefined,
cooldown: usize = 0,
score: i32 = 0,
animation_frames: ?usize = null,
game_over_timer: ?usize = null,
animations: [16]Animation = undefined,
animations_len: usize = 0,

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
    self.draw();
    if (self.game_over_timer) |*timer| {
        if (timer.* == 0) return self.gameOver();
        timer.* -= 1;
        return;
    }
    if (self.animation_frames) |*frame| {
        if (frame.* > 0) {
            frame.* -= 1;
            return;
        }
        self.animation_frames = null;
        self.animations_len = 0;
        self.postMove();
    }
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

fn addAnimation(self: *ZoabGame, animation: Animation) void {
    self.animations[self.animations_len] = animation;
    self.animations_len += 1;
}

fn makeAnimations(self: *ZoabGame, dir: Direction) bool {
    for (0..4) |j| {
        for (0..4) |i| {
            const cell = self.grid[j][i];
            if (cell == self.next_grid[j][i]) continue;
            var merged = false;
            const start: ?u4 = if (cell == 0) null else @intCast(j * 4 + i);
            const end: u4 = switch (dir) {
                .down => blk: {
                    for (j..4) |k| {
                        if (self.next_grid[k][i] != 0) {
                            if (self.next_grid[k][i] == cell + 1) {
                                merged = true;
                            }
                            break :blk @intCast(k * 4 + i);
                        }
                    }
                    if (self.next_grid[j][i] == cell + 1) {
                        merged = true;
                    }
                    break :blk @intCast(j * 4 + i);
                },
                .up => blk: {
                    for (0..j) |k| {
                        if (self.next_grid[k][i] != 0) {
                            if (self.next_grid[k][i] == cell + 1) {
                                merged = true;
                            }
                            break :blk @intCast(k * 4 + i);
                        }
                    }
                    if (self.next_grid[j][i] == cell + 1) {
                        merged = true;
                    }
                    break :blk @intCast(j * 4 + i);
                },
                .left => blk: {
                    for (0..i) |k| {
                        if (self.next_grid[j][k] != 0) {
                            if (self.next_grid[j][k] == cell + 1) {
                                merged = true;
                            }
                            break :blk @intCast(j * 4 + k);
                        }
                    }
                    if (self.next_grid[j][i] == cell + 1) {
                        merged = true;
                    }
                    break :blk @intCast(j * 4 + i);
                },
                .right => blk: {
                    for (i..4) |k| {
                        if (self.next_grid[j][k] != 0) {
                            if (self.next_grid[j][k] == cell + 1) {
                                merged = true;
                            }
                            break :blk @intCast(j * 4 + k);
                        }
                    }
                    if (self.next_grid[j][i] == cell + 1) {
                        merged = true;
                    }
                    break :blk @intCast(j * 4 + i);
                }
            };
            self.addAnimation(.{
                .dir = dir,
                .start = start,
                .end = end,
                .merged = merged,
                .value = cell,
            });
        }
    }
    return self.animations_len > 0;
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
    if (self.makeAnimations(dir)) {
        self.animation_frames = ANIM_DURATION;
    }
}

fn postMove(self: *ZoabGame) void {
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
            const tile_value = self.grid[j][i];
            if (tile_value != self.next_grid[j][i]) continue;
            const x: f32 = @floatFromInt(PANEL_X + i * TILE_SIZE + i * TILE_PADDING + TILE_PADDING);
            const y: f32 = @floatFromInt(PANEL_Y + j * TILE_SIZE + j * TILE_PADDING + TILE_PADDING);
            const size: f32 = @floatFromInt(TILE_SIZE);
            const rect = rl.Rectangle.init(x, y, size, size);
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
    for (0..self.animations_len) |i| {
        self.drawAnimationFrame(self.animations[i]);
    }
}

fn drawAnimationFrame(self: ZoabGame, animation: Animation) void {
    if (animation.start) |start| {
        return self.drawMovement(start, animation.end, animation.value);
    }
    self.drawMerge(animation.end, animation.value);
}

fn drawMovement(self: ZoabGame, start: u4, end: u4, value: u4) void {
    const istart = start % 4;
    const jstart = start / 4;
    const xstart: f32 = @floatFromInt(PANEL_X + istart * TILE_SIZE + istart * TILE_PADDING + TILE_PADDING);
    const ystart: f32 = @floatFromInt(PANEL_Y + jstart * TILE_SIZE + jstart * TILE_PADDING + TILE_PADDING);
    const iend = end % 4;
    const jend = end / 4;
    const xend: f32 = @floatFromInt(PANEL_X + iend * TILE_SIZE + iend * TILE_PADDING + TILE_PADDING);
    const yend: f32 = @floatFromInt(PANEL_Y + jend * TILE_SIZE + jend * TILE_PADDING + TILE_PADDING);
    const xdist = (xend - xstart) * @as(f32, @floatFromInt(self.animation_frames.?)) / @as(f32, @floatFromInt(ANIM_DURATION));
    const ydist = (yend - ystart) * @as(f32, @floatFromInt(self.animation_frames.?)) / @as(f32, @floatFromInt(ANIM_DURATION));
    const x = xstart + xdist;
    const y = ystart + ydist;

    const size: f32 = @floatFromInt(TILE_SIZE);
    const rect = rl.Rectangle.init(x, y, size, size);
    rl.drawRectangleRounded(rect, 0.1, 15, TILE_COLORS[value]);
}

fn drawMerge(self: ZoabGame, square: u4, value: u4) void {
    const i = square % 4;
    const j = square / 4;
    const x: f32 = @floatFromInt(PANEL_X + i * TILE_SIZE + i * TILE_PADDING + TILE_PADDING);
    const y: f32 = @floatFromInt(PANEL_Y + j * TILE_SIZE + j * TILE_PADDING + TILE_PADDING);
    const size: f32 = @as(f32, @floatFromInt(TILE_SIZE * self.animation_frames.?)) / @as(f32, @floatFromInt(ANIM_DURATION));
    const rect = rl.Rectangle.init(x, y, size, size);
    rl.drawRectangleRounded(rect, 0.1, 15, TILE_COLORS[value]);
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
