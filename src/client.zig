const std = @import("std");
const dprint = std.debug.print;
const Allocator = std.mem.Allocator;
pub const io_mode = .evented;

const ClientInfo = struct {
    name: []u8,

    fn init(allocator: *Allocator, name: []const u8) !ClientInfo {
        return ClientInfo{
            .name = try allocator.dupe(u8, name),
        };
    }

    fn deinit(self: *ClientInfo, allocator: *Allocator) void {
        allocator.free(self.name);
    }

    // Change from anytype to Writer that has (anytype, anytype, anytype) or something like that.
    fn serialize(self: *ClientInfo, writer: anytype) !void {
        try writer.writeIntLittle(usize, self.name.len);
        try writer.writeAll(self.name);
    }

    // Change from anytype to Reader that has (anytype, anytype, anytype) or something like that.
    fn deserialize(allocator: *Allocator, reader: anytype) !ClientInfo {
        const name_len = try reader.readIntLittle(usize);
        var name = try allocator.alloc(u8, name_len);
        errdefer allocator.free(name);

        try reader.readNoEof(name);

        return ClientInfo{
            .name = name,
        };
    }
};

pub fn start(ip: []const u8, port: u16) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;
    const connFile = std.net.tcpConnectToHost(allocator, ip, port) catch |err| {
        dprint("{}\n", .{err});
        return err;
    };
    defer connFile.close();
    const connReader = connFile.reader();
    const connWriter = connFile.writer();
    const stdinFile = std.io.getStdIn();
    // defer stdinFile.close();
    // defer stdoutFile.close();
    const stdinReader = stdinFile.reader();

    // Serilizing

    // var clientInfo = try ClientInfo.init(allocator, "bruhJ");
    // try clientInfo.serialize(connWriter);
    // clientInfo.deinit(allocator);

    try getInfo(allocator, stdinReader, connWriter);

    var getMessageFrame = async getMessage(allocator, connReader);
    while (true) {
        // var msg = try allocator.create([]u8);
        // // if (stdinReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |msg| {
        // //     connWriter.print("{}\r\n", .{msg}) catch {
        // //         continue;
        // //     };
        // // } else |_| {
        // //     continue;
        // // }

        // if (stdinReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |tmsg| {
        //     msg.* = tmsg;
        // } else |_| {
        //     continue;
        // }

        // connWriter.print("{}\r\n", .{msg.*}) catch {};

        // allocator.destroy(msg);
        var msg = stdinReader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |_| continue;
        connWriter.print("{s}\r\n", .{msg}) catch {};
        allocator.free(msg);
    }
    try await getMessageFrame;
}

fn getInfo(allocator: *Allocator, stdinReader: anytype, connWriter: anytype) !void {
    stdoutPrint("\x1b[33;1mIdentifier:\x1b[0m ", .{});
    // const name = try stdinReader.readUntilDelimiterAlloc(allocator, '\n', 12);
    var clientInfo = try ClientInfo.init(allocator, try stdinReader.readUntilDelimiterAlloc(allocator, '\n', 12));
    try clientInfo.serialize(connWriter);
    clientInfo.deinit(allocator);
}

fn getMessage(allocator: *Allocator, connReader: anytype) !void {
    // const stdoutFile = std.io.getStdOut();
    // defer stdoutFile.close();
    // const stdoutWriter = stdoutFile.writer();
    // const held = stdout_mutex.acquire();
    // defer held.release();
    // const stdoutWriter = std.io.getStdOut().writer();
    // var buffer = std.io.bufferedWriter(stdoutWrit);
    // var bufOut = buffer.writer();
    while (true) {
        // var msg = try allocator.create([]u8);
        var msg = connReader.readUntilDelimiterAlloc(allocator, '\n', 1024) catch |_| continue;
        // NEED TO MAKE THIS STDOUT

        // WHY WONT EXACT PORT OF PRINT FOR STDOUT WORK BUT PRINT WITH STDERR WILL !
        stdoutPrint("{s}\r\n", .{msg});
        // dprint("{}\r\n", .{msg}); // Gonna be stuck with this for a while until you figure out the issue with stdout.

        // try stdoutWriter.print("{}\r\n", .{msg});

        // stdoutWriter.print("{}\r\n", .{msg}) catch continue;

        // stdoutPrint("{}\r\n", .{msg});

        // bufOut.print("{}\r\n", .{msg}) catch continue;
        // try buffer.flush();

        // allocator.destroy(msg);
        allocator.free(msg);
    }
}

fn stdoutPrint(comptime fmt: []const u8, args: anytype) void {
    var stdout = std.io.getStdOut();
    stdout.intended_io_mode = .blocking;
    stdout.writer().print(fmt, args) catch return;
}
