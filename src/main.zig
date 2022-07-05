const std = @import("std");
const eco = @import("eco");
const io = std.io;

fn f() {
    const S = struct {
        var x: isize = 0;
    }
    var i = 0;
    var id = 0;
    const stdout = io.getStdOut().writer();

    x += 1;
    id = x;
    while (i < 10) {
        try stdout.print("{d} {d}\n", .{id, i});
        _ = eco.eco_yield();
        i += 1;
    }
}

pub fn main() !void {
    eco.eco_init();
    eco.eco_go(f);
    eco.eco_go(f);
    _ = eco.eco_return(1);
}
