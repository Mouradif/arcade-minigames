const MenuComponent = @This();

const rl = @import("raylib");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");

pub const Props = struct {
    items: [][:0]const u8,
    width: i32 = 400,
    item_height: i32 = 48,
    margin_top: i32 = 0,
    onSelect: *const fn (context: *GameContext, item: [*:0]const u8) void,
};

context: *GameContext,
props: Props,
position: usize = 0,

pub fn init(context: *GameContext, props: Props) MenuComponent {
    return .{
        .context = context,
        .props = props,
    };
}

pub fn deinit(self: *MenuComponent) void {
    _ = self;
}

pub fn tick(self: *MenuComponent) void {
    self.draw();
    if (!self.context.isRunning()) {
        return;
    }
    if (rl.isKeyReleased(.enter)) {
        self.props.onSelect(self.context, self.props.items[self.position]);
        return;
    }
    if (self.position > 0 and rl.isKeyReleased(.up)) {
        self.position -= 1;
    }
    if (self.position < self.props.items.len - 1 and rl.isKeyReleased(.down)) {
        self.position += 1;
    }
}

fn draw(self: MenuComponent) void {
    const center_x: i32 = @divTrunc(Constants.WIDTH, 2) - @divTrunc(self.props.width, 2);
    const items_len: i32 = @intCast(self.props.items.len);
    rl.drawRectangle(center_x, self.props.margin_top, self.props.width, self.props.item_height * items_len, rl.Color.black);
    for (self.props.items, 0..) |item, i| {
        const item_y = @as(i32, @intCast(i)) * self.props.item_height + self.props.margin_top;
        const is_selected = i == self.position;
        if (is_selected) {
            rl.drawRectangle(center_x + 5, item_y + 5, self.props.width - 10, self.props.item_height - 10, rl.Color.gray);
        }
        const text_color = if (is_selected) rl.Color.black else rl.Color.light_gray;
        rl.drawText(item, center_x + 15, item_y + 12, 18, text_color);
    }
}
