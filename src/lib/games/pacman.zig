const PacmanGame = @This();

const rl = @import("raylib");
const std = @import("std");

const GameContext = @import("../game_context.zig");

context: *GameContext,

pub fn init(self: *PacmanGame, context: *GameContext) void {
    self.context = context;
}

pub fn deinit(self: *PacmanGame) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *PacmanGame) void {
    _ = self;
}
