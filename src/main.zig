const std = @import("std");
const eco = @import("eco");
const debug = std.debug;

fn f() void {
    const S = struct {
        var x: isize = 0;
    };
    var i: isize = 0;
    var id: isize = 0;

    S.x += 1;
    id = S.x;
    while (i < 10) {
        debug.print("{d} {d}\n", .{id, i});
        _ = eco.eco_yield();
        i += 1;
    }
}

pub fn main() !void {
    eco.eco_init();
    try eco.eco_go(f);
    try eco.eco_go(f);
    eco.eco_return(0);
}
