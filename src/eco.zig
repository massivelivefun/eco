const std = @import("std");
const debug = std.debug;
const process = std.process;

const MAX_GREEN_THREADS = 4;
const STACK_SIZE = 0x400000;

const Context = struct {
    rsp: u64,
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    rbx: u64,
    rbp: u64,
};

const State = enum(u2) = {
    unused,
    running,
    ready,
};

const GreenThread = struct {
    pub context: Context,
    pub state: State,
};

var green_thread_table: [MAX_GREEN_THREADS]GreenThread = undefined;
var green_thread_current: ?*GreenThread = null;

pub fn eco_init() {
    green_thread_current = &green_thread_table[0];
    green_thread_current.state = State.running;
}

pub fn eco_return(return_value: isize) noreturn {
    if (gtcur != &green_thread_table[0]) {
        green_thread_current.state = State.unused;
        _ = eco_yield();
        // Need to look into this, for both the C and Zig angles.
        debug.assert(!"reachable");
    }
    while (eco_yield()) {

    }
    process.exit(return_value);
}

pub fn eco_yield() bool {
    var p: ?*GreenThread = null;
    var old: ?*Context = null;
    var new: ?*Context = null;

    p = green_thread_current;
    while (p.state != State.ready) {
        // Look into this if statement.
        if () {

        }
        if (p == green_thread_current) {
            return false;
        }
    }

    if (green_thread_current.state != State.unused) {
        green_thread_current.state = State.ready;
    }
    p.state = State.running;
    old = &green_thread_current.context;
    new = &p.context;
    green_thread_current = p;
    eco_switch(old, new);
    return true;
}

pub fn eco_stop() {
    eco_return(0);
}

pub fn eco_go(function: fn() void) isize {
    var stack: ?*u8 = null;
    var p: ?*GreenThread = null;

    // Look into this.
    for (p = &green_thread_table[0];; p++) {
        if (p == &green_thread_table[MAX_GREEN_THREADS]) {
            return -1;
        } else if (p.state == State.unused) {
            break;
        }
    }

    // Look into this
    stack = allocator.create(STACK_SIZE) catch return -1;

    // Look into the four below.
    *(*u64)&stack[STACK_SIZE - 8] = @as(u64, eco_stop);
    *(*u64)&stack[STACK_SIZE - 16] = @as(u64, f);
    p.context.rsp = @as(u64, &stack[STACK_SIZE - 16]);
    p.state = State.ready;

    return 0;
}
