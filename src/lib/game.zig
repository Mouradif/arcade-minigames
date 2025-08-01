const PongGame = @import("games/pong.zig");
const SnakeGame = @import("games/snake.zig");
const ZoabGame = @import("games/zoab.zig");
const TetrisGame = @import("games/tetris.zig");
const PacmanGame = @import("games/pacman.zig");
const BreakerGame = @import("games/breaker.zig");

const pong = "Pong";
const snake = "Snake";
const zoab = "2048";
const tetris = "Tetris";
const breaker = "Breaker";
const pacman = "Pacman";

pub const Game = enum {
    pong,
    snake,
    zoab,
    tetris,
    breaker,
    pacman,

    pub fn getInstanceAs(T: type, ptr: *anyopaque) T {
        const instance: T = @alignCast(@ptrCast(ptr));
        return @as(T, instance);
    }

    pub fn getName(self: Game) [:0]const u8 {
        return switch (self) {
            .pong => pong,
            .snake => snake,
            .zoab => zoab,
            .tetris => tetris,
            .breaker => breaker,
            .pacman => pacman,
        };
    }
};
