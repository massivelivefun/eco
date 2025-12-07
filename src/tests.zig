const std = @import("std");
const testing = std.testing;
const eco = @import("eco");

var counter: usize = 0;

fn increment() void {
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        counter += 1;
        _ = eco.eco_yield();
    }
}

test "basic single thread" {
    // Reset state
    counter = 0;
    eco.eco_init();
    
    // Spawn one thread
    try eco.eco_go(increment);
    
    // Run loop
    eco.eco_wait();
    
    // 5 increments
    try testing.expectEqual(@as(usize, 5), counter);
}

fn thread_a() void {
    counter += 1; // 1
    _ = eco.eco_yield();
    counter += 1; // 3
}

fn thread_b() void {
    counter += 1; // 2
    _ = eco.eco_yield();
    counter += 1; // 4
}

test "two threads interleaved" {
    counter = 0;
    eco.eco_init();

    try eco.eco_go(thread_a);
    try eco.eco_go(thread_b);

    eco.eco_wait();

    try testing.expectEqual(@as(usize, 4), counter);
}
