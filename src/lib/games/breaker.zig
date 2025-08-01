const BreakerGame = @This();

const rl = @import("raylib");
const std = @import("std");

const GameContext = @import("../game_context.zig");

context: *GameContext,

pub fn init(self: *BreakerGame, context: *GameContext) void {
    self.context = context;
}

pub fn deinit(self: *BreakerGame) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *BreakerGame) void {
    _ = self;
}
