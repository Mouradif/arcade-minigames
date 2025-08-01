const Utils = @import("utils.zig");

pub const WIDTH: i32 = 1280;
pub const HEIGHT: i32 = 726;
pub const TILE_SIZE: i32 = 12;
pub const SCREEN_X_PADDING: i32 = 100;
pub const SCREEN_Y_PADDING: i32 = 80;
pub const GRID_X_COUNT: i32 = @divTrunc(WIDTH - SCREEN_X_PADDING * 2, TILE_SIZE);
pub const GRID_Y_COUNT: i32 = @divTrunc(HEIGHT - SCREEN_Y_PADDING * 2, TILE_SIZE);
pub const SCREEN_WIDTH: i32 = GRID_X_COUNT * TILE_SIZE;
pub const SCREEN_HEIGHT: i32 = GRID_Y_COUNT * TILE_SIZE; // 564
pub const DIR_UP = Utils.Vector2i32{ 0, -1 };
pub const DIR_DOWN = Utils.Vector2i32{ 0, 1 };
pub const DIR_LEFT = Utils.Vector2i32{ -1, 0 };
pub const DIR_RIGHT = Utils.Vector2i32{ 1, 0 };
