const GameContext = @This();

const std = @import("std");

const GameScreen = @import("game_screen.zig").GameScreen;
const GameOutcome = @import("game_outcome.zig").GameOutcome;
const GameState = @import("game_state.zig").GameState;

const LogoScreen = @import("screens/logo.zig");
const TitleScreen = @import("screens/title.zig");
const GameSelectionScreen = @import("screens/game_selection.zig");
const GameplayScreen = @import("screens/gameplay.zig");
const EndingScreen = @import("screens/ending.zig");

const PauseMenu = @import("components/pause.zig");

allocator: std.mem.Allocator,
state: GameState = .running,
outcome: GameOutcome = .undefined,
screen: ?GameScreen = null,
screen_ptr: ?*anyopaque = null,
pause_menu: ?PauseMenu = null,
should_exit: bool = false,

pub fn init(allocator: std.mem.Allocator) GameContext {
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *GameContext) void {
    self.deinitScreen();
}

fn hasScreen(self: *GameContext) bool {
    if (self.screen) |_| {
        if (self.screen_ptr) |_| {
            return true;
        }
        @panic("We have a screen but no screen ptr");
    }
    return false;
}

fn deinitScreen(self: *GameContext) void {
    if (!self.hasScreen()) {
        return;
    }
    switch (self.screen.?) {
        .logo => GameScreen.getInstanceAs(*LogoScreen, self.screen_ptr.?).deinit(),
        .title => GameScreen.getInstanceAs(*TitleScreen, self.screen_ptr.?).deinit(),
        .game_selection => GameScreen.getInstanceAs(*GameSelectionScreen, self.screen_ptr.?).deinit(),
        .gameplay => GameScreen.getInstanceAs(*GameplayScreen, self.screen_ptr.?).deinit(),
        .ending => GameScreen.getInstanceAs(*EndingScreen, self.screen_ptr.?).deinit(),
    }
    self.screen_ptr = null;
}

fn initScreen(self: *GameContext, T: type, props: anytype) !void {
    var scr = try self.allocator.create(T);
    scr.init(self, props);
    self.screen_ptr = @alignCast(@ptrCast(scr));
}

fn pause(self: *GameContext) void {
    self.state = .paused;
    self.pause_menu = PauseMenu.init(self);
}

fn unpause(self: *GameContext) void {
    self.state = .running;
    self.pause_menu.?.deinit();
    self.pause_menu = null;
}

pub fn toggleState(self: *GameContext) void {
    if (self.isRunning()) {
        self.pause();
    } else {
        self.unpause();
    }
}

pub fn setScreen(self: *GameContext, screen: ?GameScreen, screen_type: ?type, props: anytype) !void {
    self.deinitScreen();
    self.screen = screen;
    if (screen_type) |scr| {
        try self.initScreen(scr, props);
    }
}

pub fn setOutcome(self: *GameContext, outcome: GameOutcome) void {
    self.outcome = outcome;
}

pub fn isRunning(self: GameContext) bool {
    return self.pause_menu == null;
}

pub fn exit(self: *GameContext) void {
    self.should_exit = true;
}

pub fn draw(self: *GameContext) void {
    if (!self.hasScreen()) {
        return;
    }
    switch (self.screen.?) {
        .logo => @as(*LogoScreen, @alignCast(@ptrCast(self.screen_ptr.?))).tick(),
        .title => @as(*TitleScreen, @alignCast(@ptrCast(self.screen_ptr.?))).tick(),
        .game_selection => @as(*GameSelectionScreen, @alignCast(@ptrCast(self.screen_ptr.?))).tick(),
        .gameplay => @as(*GameplayScreen, @alignCast(@ptrCast(self.screen_ptr.?))).tick(),
        .ending => @as(*EndingScreen, @alignCast(@ptrCast(self.screen_ptr.?))).tick(),
    }

    if (!self.isRunning()) {
        self.pause_menu.?.tick();
    }
}
