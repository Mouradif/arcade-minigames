const GameContext = @import("game_context.zig");

pub const GameScreen = enum {
    logo,
    title,
    game_selection,
    gameplay,
    ending,

    pub fn getInstanceAs(T: type, ptr: *anyopaque) T {
        const instance: T = @alignCast(@ptrCast(ptr));
        return @as(T, instance);
    }
};
