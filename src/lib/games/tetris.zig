const TetrisGame = @This();

const rl = @import("raylib");
const std = @import("std");

const GameContext = @import("../game_context.zig");

context: *GameContext,

pub fn init(self: *TetrisGame, context: *GameContext) void {
    self.context = context;
}

pub fn deinit(self: *TetrisGame) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *TetrisGame) void {
    _ = self;
}
