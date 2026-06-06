const Gateway = @import("../protocol.zig");

pub const RawHandler = struct {
    ptr: *anyopaque,
    callFn: *const fn (ptr: *anyopaque, dispatch: Gateway.ParsedDispatch) anyerror!void,

    pub fn call(self: RawHandler, dispatch: Gateway.ParsedDispatch) !void {
        try self.callFn(self.ptr, dispatch);
    }
};
