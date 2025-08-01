const GameSelectionScreen = @This();

const std = @import("std");
const rl = @import("raylib");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const Game = @import("../game.zig").Game;
const GameplayScreen = @import("gameplay.zig");
const Utils = @import("../utils.zig");

const MenuComponent = @import("../components/menu.zig");

const message = "Select a game in the list";
const size = 25;

const labels: [6][:0]const u8 = .{
    "Pong",
    "Snake",
    "2048",
    "Tetris",
    "Breaker",
    "Pacman",
};

const games: [6]Game = .{
    .pong,
    .snake,
    .zoab,
    .tetris,
    .breaker,
    .pacman,
};

pub const Props = struct {};

context: *GameContext,
props: Props,
centered_x: i32,
menu: MenuComponent,

fn onSelect(context: *GameContext, item: [*:0]const u8) void {
    if (std.mem.eql(u8, std.mem.span(item), "Snake")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .snake,
        }) catch {
            @panic("Could not set screen");
        };
    } else if (std.mem.eql(u8, std.mem.span(item), "Pong")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .pong,
        }) catch {
            @panic("Could not set screen");
        };
    } else if (std.mem.eql(u8, std.mem.span(item), "2048")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .zoab,
        }) catch {
            @panic("Could not set screen");
        };
    } else if (std.mem.eql(u8, std.mem.span(item), "Tetris")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .tetris,
        }) catch {
            @panic("Could not set screen");
        };
    } else if (std.mem.eql(u8, std.mem.span(item), "Breaker")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .breaker,
        }) catch {
            @panic("Could not set screen");
        };
    } else if (std.mem.eql(u8, std.mem.span(item), "Pacman")) {
        context.setScreen(.gameplay, GameplayScreen, GameplayScreen.Props{
            .game = .pacman,
        }) catch {
            @panic("Could not set screen");
        };
    } else {
        std.debug.print("Unsupported game {s}\n", .{item});
    }
}

pub fn init(self: *GameSelectionScreen, context: *GameContext, props: Props) void {
    self.context = context;
    self.props = props;
    self.centered_x = Utils.centerText(message, size);

    var items: [][:0]const u8 = self.context.allocator.alloc([:0]const u8, 6) catch {
        @panic("Failed to allocate menu items");
    };
    inline for (0..6) |i| {
        items[i] = labels[i];
    }
    self.menu = MenuComponent.init(context, .{
        .items = items,
        .margin_top = 100,
        .onSelect = onSelect,
    });
}

pub fn deinit(self: *GameSelectionScreen) void {
    self.context.allocator.free(self.menu.props.items);
    self.context.allocator.destroy(self);
}

pub fn tick(self: *GameSelectionScreen) void {
    self.draw();
    self.menu.tick();
}

fn draw(self: GameSelectionScreen) void {
    rl.drawText(message, self.centered_x, 30, 25, rl.Color.white);
}
