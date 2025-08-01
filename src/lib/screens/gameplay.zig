const GameplayScreen = @This();

const rl = @import("raylib");
const Game = @import("../game.zig").Game;
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");

const PongGame = @import("../games/pong.zig");
const SnakeGame = @import("../games/snake.zig");
const ZoabGame = @import("../games/zoab.zig");
const BreakerGame = @import("../games/breaker.zig");
const TetrisGame = @import("../games/tetris.zig");
const PacmanGame = @import("../games/pacman.zig");

const Utils = @import("../utils.zig");

const font_size = 24;

pub const Props = struct {
    game: Game,
};

context: *GameContext,
props: Props,
game_ptr: *anyopaque,
text: [:0]const u8,
text_x: i32,

pub fn init(self: *GameplayScreen, context: *GameContext, props: Props) void {
    self.context = context;
    self.props = props;
    self.text = self.props.game.getName();
    self.text_x = Utils.centerText(self.text, font_size);
    switch (self.props.game) {
        .pong => self.initGame(PongGame),
        .snake => self.initGame(SnakeGame),
        .zoab => self.initGame(ZoabGame),
        .breaker => self.initGame(BreakerGame),
        .tetris => self.initGame(TetrisGame),
        .pacman => self.initGame(PacmanGame),
    }
}

fn initGame(self: *GameplayScreen, T: type) void {
    var scr = self.context.allocator.create(T) catch {
        @panic("Could not create game");
    };
    scr.init(self.context);
    self.game_ptr = @alignCast(@ptrCast(scr));
}

fn deinitGame(self: *GameplayScreen, T: type) void {
    Game.getInstanceAs(*T, self.game_ptr).deinit();
}

pub fn deinit(self: *GameplayScreen) void {
    switch (self.props.game) {
        .pong => self.deinitGame(PongGame),
        .snake => self.deinitGame(SnakeGame),
        .zoab => self.deinitGame(ZoabGame),
        .breaker => self.deinitGame(BreakerGame),
        .tetris => self.deinitGame(TetrisGame),
        .pacman => self.deinitGame(PacmanGame),
    }
    self.context.allocator.destroy(self);
}

pub fn destroy(self: *GameplayScreen) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *GameplayScreen) void {
    self.draw();
    switch (self.props.game) {
        .pong => @as(*PongGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
        .snake => @as(*SnakeGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
        .zoab => @as(*ZoabGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
        .breaker => @as(*BreakerGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
        .tetris => @as(*TetrisGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
        .pacman => @as(*PacmanGame, @alignCast(@ptrCast(self.game_ptr))).tick(),
    }
}

fn draw(self: GameplayScreen) void {
    rl.drawText(self.text, self.text_x, 36, font_size, rl.Color.white);
}
