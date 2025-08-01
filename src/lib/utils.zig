const rl = @import("raylib");
const Constants = @import("constants.zig");

pub const Vector2i32 = @Vector(2, i32);
pub const Vector2f32 = @Vector(2, f32);

pub fn itoa(T: type, buffer: [:0]u8, number: T) [:0]u8 {
    var digits: usize = 1;
    var n = number;
    if (n < 0) {
        buffer[0] = '-';
        digits += 1;
        n *= -1;
    }

    var tmp = n;
    while (tmp >= 10) : (tmp = @divTrunc(tmp, 10)) {
        digits += 1;
    }
    var index: usize = 0;
    while (true) {
        buffer[digits - 1 - index] = @as(u8, @intCast(@mod(n, 10))) + '0';
        index += 1;
        n = @divTrunc(n, 10);
        if (n == 0) {
            break;
        }
    }
    buffer[digits] = 0;
    return buffer;
}

pub fn centerText(text: [:0]const u8, font_size: i32) i32 {
    return @divTrunc(Constants.WIDTH, 2) - @divTrunc(rl.measureText(text, font_size), 2);
}

pub fn drawTile(coords: Vector2i32, color: rl.Color) void {
    rl.drawRectangle(
        coords[0] * Constants.TILE_SIZE + Constants.SCREEN_X_PADDING,
        coords[1] * Constants.TILE_SIZE + Constants.SCREEN_Y_PADDING,
        Constants.TILE_SIZE,
        Constants.TILE_SIZE,
        color,
    );
}

pub fn randomPosition() Vector2i32 {
    const random_x = rl.getRandomValue(0, Constants.GRID_X_COUNT - 1);
    const random_y = rl.getRandomValue(0, Constants.GRID_Y_COUNT - 1);
    return Vector2i32{ random_x, random_y };
}
