const EndingScreen = @This();

const rl = @import("raylib");
const GameContext = @import("../game_context.zig");
const Constants = @import("../constants.zig");
const Utils = @import("../utils.zig");
const GameSelectionScreen = @import("game_selection.zig");

const game_over_text = "Game Over";
const score_text = "Score";
const choice_text = "Press [Enter] to return to game selection";

const game_over_text_font_size = 32;
const score_text_font_size = 64;
const score_font_size = 64;
const choice_font_size = 22;

const delay_before_score = 60;
const score_animation_duration = 90;
const delay_before_choice = 30;

pub const Props = struct {
    score: i32,
};

context: *GameContext,
props: Props,
current_frame: usize,
text: [:0]const u8,
text_x: i32,
score_text_x: i32,
choice_x: i32,

pub fn init(self: *EndingScreen, context: *GameContext, props: Props) void {
    self.context = context;
    self.props = props;
    self.current_frame = 0;
    self.text = game_over_text;
    self.text_x = Utils.centerText(game_over_text, game_over_text_font_size);
    self.score_text_x = Utils.centerText(score_text, score_text_font_size);
    self.choice_x = Utils.centerText(choice_text, choice_font_size);
}

pub fn deinit(self: *EndingScreen) void {
    self.context.allocator.destroy(self);
}

pub fn tick(self: *EndingScreen) void {
    self.draw();
    if (self.current_frame < delay_before_score + score_animation_duration + delay_before_choice) {
        self.current_frame += 1;
    } else {
        if (rl.isKeyReleased(.enter)) {
            self.context.setScreen(.game_selection, GameSelectionScreen, GameSelectionScreen.Props{}) catch {
                @panic("Could not set screen");
            };
        }
    }
}

fn drawScore(self: EndingScreen) void {
    if (self.current_frame < 60) {
        return;
    }
    rl.drawText(score_text, self.score_text_x, 180, score_text_font_size, rl.Color.yellow);
    const progress: i32 = @min(self.current_frame - 60, score_animation_duration);
    const percent: i32 = @divTrunc(progress * 100, score_animation_duration);
    const score: i32 = @divTrunc(self.props.score * percent, 100);
    var buffer: [10]u8 = undefined;
    const buffer_ptr = @as([:0]u8, @ptrCast(&buffer));
    const ascii_score = Utils.itoa(i32, buffer_ptr, score);
    const score_x = Utils.centerText(ascii_score, score_font_size);
    rl.drawText(ascii_score, score_x, 250, score_font_size, rl.Color.yellow);
}

fn drawChoice(self: EndingScreen) void {
    if (self.current_frame < delay_before_score + score_animation_duration + delay_before_choice) {
        return;
    }
    rl.drawText(choice_text, self.choice_x, Constants.HEIGHT - choice_font_size - 250, choice_font_size, rl.Color.white);
}

fn draw(self: EndingScreen) void {
    rl.drawText(self.text, self.text_x, 24, game_over_text_font_size, rl.Color.white);
    self.drawScore();
    if (self.current_frame >= delay_before_score + score_animation_duration + delay_before_choice) {
        self.drawChoice();
    }
}
