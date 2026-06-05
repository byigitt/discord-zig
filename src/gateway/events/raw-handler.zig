const std = @import("std");
const Gateway = @import("../protocol.zig");
const Interactions = @import("../../interactions/mod.zig");

const Root = @import("../events.zig");
const Dispatcher = Root.Dispatcher;
const interactionType = Root.interactionType;
const rawHandler = Root.rawHandler;

pub const RawHandler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, dispatch: Gateway.ParsedDispatch) anyerror!void,

    pub fn call(self: RawHandler, dispatch: Gateway.ParsedDispatch) !void {
        try self.callFn(self.ptr, dispatch);
    }
};
