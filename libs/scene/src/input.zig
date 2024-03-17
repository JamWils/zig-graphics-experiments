pub const KEY_COUNT: i32 = 128;

pub const KeyState = struct {
    pressed: bool = false,
    state: bool = false,
    current: bool = false,
};

pub const MouseCoords = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const MouseState = struct {
    left: KeyState,
    right: KeyState,
    middle: KeyState,
    scroll: MouseCoords,
    window: MouseCoords,
    relative: MouseCoords,
};

pub const Input = struct {
    keys: []KeyState,
    mouse: MouseState,
};

pub const KEY_UNKNOWN: i32 = 0;
pub const KEY_RETURN: i32 = 13; // '\r'
pub const KEY_ESCAPE: i32 = 27;
pub const KEY_BACKSPACE: i32 = 8; // '\b'
pub const KEY_TAB: i32 = 9; // '\t'
pub const KEY_SPACE: i32 = 32; // ' '
pub const KEY_EXCLAIM: i32 = 33; // '!'
pub const KEY_QUOTEDBL: i32 = 34; // '"'
pub const KEY_HASH: i32 = 35; // '#'
pub const KEY_PERCENT: i32 = 37; // '%'
pub const KEY_DOLLAR: i32 = 36; // '$'
pub const KEY_AMPERSAND: i32 = 38; // '&'
pub const KEY_QUOTE: i32 = 39; // '\''
pub const KEY_LEFT_PAREN: i32 = 40; // '('
pub const KEY_RIGHT_PAREN: i32 = 41; // ')'
pub const KEY_ASTERISK: i32 = 42; // '*'
pub const KEY_PLUS: i32 = 43; // '+'
pub const KEY_COMMA: i32 = 44; // ','
pub const KEY_MINUS: i32 = 45; // '-'
pub const KEY_PERIOD: i32 = 46; // '.'
pub const KEY_SLASH: i32 = 47; // '/'

pub const KEY_0: i32 = 48; // '0'
pub const KEY_1: i32 = 49; // '1'
pub const KEY_2: i32 = 50; // '2'
pub const KEY_3: i32 = 51; // '3'
pub const KEY_4: i32 = 52; // '4'
pub const KEY_5: i32 = 53; // '5'
pub const KEY_6: i32 = 54; // '6'
pub const KEY_7: i32 = 55; // '7'
pub const KEY_8: i32 = 56; // '8'
pub const KEY_9: i32 = 57; // '9'

pub const KEY_COLON: i32 = 58; // ':'
pub const KEY_SEMICOLON: i32 = 59; // ';'
pub const KEY_LESS: i32 = 60; // '<'
pub const KEY_EQUAL: i32 = 61; // '='
pub const KEY_GREATER: i32 = 62; // '>'
pub const KEY_QUESTION: i32 = 63; // '?'
pub const KEY_AT: i32 = 64; // '@'
pub const KEY_LEFT_BRACKET: i32 = 91; // '['
pub const KEY_RIGHT_BRACKET: i32 = 93; // ']'
pub const KEY_BACKSLASH: i32 = 92; // '\\'
pub const KEY_CARET: i32 = 94; // '^'
pub const KEY_UNDERSCORE: i32 = 95; // '_'
pub const KEY_GRAVE_ACCENT: i32 = 96; // '`'
pub const KEY_APOSTROPHE: i32 = 39; // Same as KEY_QUOTE

pub const KEY_A: i32 = 97; // 'a'
pub const KEY_B: i32 = 98; // 'b'
pub const KEY_C: i32 = 99; // 'c'
pub const KEY_D: i32 = 100; // 'd'
pub const KEY_E: i32 = 101; // 'e'
pub const KEY_F: i32 = 102; // 'f'
pub const KEY_G: i32 = 103; // 'g'
pub const KEY_H: i32 = 104; // 'h'
pub const KEY_I: i32 = 105; // 'i'
pub const KEY_J: i32 = 106; // 'j'
pub const KEY_K: i32 = 107; // 'k'
pub const KEY_L: i32 = 108; // 'l'
pub const KEY_M: i32 = 109; // 'm'
pub const KEY_N: i32 = 110; // 'n'
pub const KEY_O: i32 = 111; // 'o'
pub const KEY_P: i32 = 112; // 'p'
pub const KEY_Q: i32 = 113; // 'q'
pub const KEY_R: i32 = 114; // 'r'
pub const KEY_S: i32 = 115; // 's'
pub const KEY_T: i32 = 116; // 't'
pub const KEY_U: i32 = 117; // 'u'
pub const KEY_V: i32 = 118; // 'v'
pub const KEY_W: i32 = 119; // 'w'
pub const KEY_X: i32 = 120; // 'x'
pub const KEY_Y: i32 = 121; // 'y'
pub const KEY_Z: i32 = 122; // 'z'
pub const KEY_DELETE: i32 = 127;

pub const KEY_RIGHT: i32 = @intCast('R');
pub const KEY_LEFT: i32 = @intCast('L');
pub const KEY_DOWN: i32 = @intCast('D');
pub const KEY_UP: i32 = @intCast('U');
pub const KEY_LEFT_CTRL: i32 = @intCast('C');
pub const KEY_LEFT_ALT: i32 = @intCast('A');
pub const KEY_LEFT_SHIFT: i32 = @intCast('S');
pub const KEY_RIGHT_CTRL: i32 = @intCast('T');
pub const KEY_RIGHT_ALT: i32 = @intCast('Z');
pub const KEY_RIGHT_SHIFT: i32 = @intCast('H');
pub const KEY_INSERT: i32 = @intCast('I');
pub const KEY_HOME: i32 = @intCast('H');
pub const KEY_END: i32 = @intCast('E');
pub const KEY_PAGE_UP: i32 = @intCast('O');
pub const KEY_PAGE_DOWN: i32 = @intCast('P');

pub fn keyDown(key: *KeyState) void {
    if (key.state) {
        key.*.pressed = false;
    } else {
        key.*.pressed = true;
    }

    key.*.state = true;
    key.*.current = true;
}

pub fn keyUp(key: *KeyState) void {
    key.*.current = false;
}

pub fn keyReset(key: *KeyState) void {
    if (!key.*.current) {
        key.*.state = false;
        key.*.pressed = false;
    } else if (key.*.state) {
        key.*.pressed = false;
    }
}
