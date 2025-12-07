const std = @import("std");
const debug = std.debug;
const process = std.process;

const MAX_GREEN_THREADS = 4;
const STACK_SIZE = 16 * 1024; // 16KB

const Context = extern struct {
    rsp: u64,
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    rbx: u64,
    rbp: u64,
    rdi: u64,
    rsi: u64,
};

extern fn eco_switch(old: *Context, new: *Context) callconv(.c) void;

const State = enum {
    unused,
    running,
    ready,
};

const GreenThread = struct {
    context: Context,
    state: State,
    stack: []u8,
};

// Global thread table
var green_thread_table: [MAX_GREEN_THREADS]GreenThread = undefined;
var green_thread_current: *GreenThread = undefined;

pub fn eco_init() void {
    // Initialize the table
    for (&green_thread_table) |*gt| {
        gt.state = .unused;
        gt.context = std.mem.zeroes(Context);
        // Do not preserve stack here if we want fresh threads, 
        // but we want to reuse memory.
        if (gt.stack.len == 0) {
            gt.stack = &.{};
        }
    }

    // Assign main thread to index 0
    green_thread_current = &green_thread_table[0];
    green_thread_current.state = .running;
}

pub fn eco_wait() void {
     while (eco_yield()) {
        // Continue yielding
    }
}

pub fn eco_return(return_value: u8) noreturn {
    // If we are not the main thread, mark as unused and yield
    if (green_thread_current != &green_thread_table[0]) {
        green_thread_current.state = .unused;
        _ = eco_yield();
        // Should never return here if switch works
        unreachable;
    }

    eco_wait();

    process.exit(return_value);
}

pub fn eco_yield() bool {
    var p: *GreenThread = green_thread_current;
    
    // Round-robin search for next ready thread
    while (true) {
        // Calculate next index
        const current_idx = @intFromPtr(p) - @intFromPtr(&green_thread_table[0]);
        const idx = @divExact(current_idx, @sizeOf(GreenThread));
        const next_idx = (idx + 1) % MAX_GREEN_THREADS;
        p = &green_thread_table[next_idx];

        if (p.state == .ready) {
            break;
        }

        if (p == green_thread_current) {
            // We circled back.
            // If current is running, keep running.
            if (green_thread_current.state == .running) {
                return false;
            }
            // If current is unused (exiting) and no one else is ready, we are done.
            return false;
        }
    }

    // If we found a thread to switch to:
    if (green_thread_current.state == .running) {
        green_thread_current.state = .ready;
    }

    const old = green_thread_current;
    green_thread_current = p;
    green_thread_current.state = .running;

    eco_switch(&old.context, &green_thread_current.context);
    return true;
}

pub fn eco_stop() callconv(.c) void {
    eco_return(0);
}

pub fn eco_go(function: *const fn() void) !void {
    var p: ?*GreenThread = null;

    // Find unused slot
    for (&green_thread_table) |*gt| {
        if (gt == &green_thread_table[0]) continue; // Skip main thread slot
        if (gt.state == .unused) {
            p = gt;
            break;
        }
    }

    if (p) |thread| {
        // Allocate stack if needed (reuse if already allocated? for simplicity alloc new or reuse)
        // For now, simple alloc.
        if (thread.stack.len == 0) {
            thread.stack = try std.heap.page_allocator.alloc(u8, STACK_SIZE);
        }

        // Setup stack
        // Stack grows down from high address
        const stack_top = @intFromPtr(thread.stack.ptr) + thread.stack.len;
        var sp = stack_top;

        // Push return address for 'function' -> eco_stop
        sp -= 8;
        const ret_addr_ptr: *u64 = @ptrFromInt(sp);
        ret_addr_ptr.* = @intFromPtr(&eco_stop);

        // Push return address for 'eco_switch' -> function
        sp -= 8;
        const func_ptr: *u64 = @ptrFromInt(sp);
        func_ptr.* = @intFromPtr(function);

        // Set RSP in context
        thread.context.rsp = sp;
        
        // Reset valid state
        thread.state = .ready;
    } else {
        return error.TooManyThreads;
    }
}
