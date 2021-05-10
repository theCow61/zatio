const std = @import("std");
const dprint = std.debug.print;
const Allocator = std.mem.Allocator;
pub const io_mode = .evented;

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
    defer stdinFile.close();
    const stdoutFile = std.io.getStdOut();
    defer stdoutFile.close();
    const stdinReader = stdinFile.reader();
    const stdoutWriter = stdoutFile.writer();
    var getMessageFrame = async getMessage(allocator, &connReader, &stdoutWriter);
    while (true) {
        var msg = try allocator.create([]u8);
        // if (stdinReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |msg| {
        //     connWriter.print("{}\r\n", .{msg}) catch {
        //         continue;
        //     };
        // } else |_| {
        //     continue;
        // }

        if (stdinReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |tmsg| {
            msg.* = tmsg;
        } else |_| {
            continue;
        }

        connWriter.print("{}\r\n", .{msg.*}) catch {};

        allocator.destroy(msg);
    }
    try await getMessageFrame;
}

fn getMessage(allocator: *Allocator, connReader: *const std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read), stdoutWriter: *const std.io.Writer(std.fs.File, std.os.WriteError, std.fs.File.write)) !void {
    // const stdoutFile = std.io.getStdOut();
    // defer stdoutFile.close();
    // const stdoutWriter = stdoutFile.writer();
    dprint("Bruh\n", .{});
    while (true) {
        dprint("Bruh\n", .{});
        var msg = try allocator.create([]u8);
        msg.* = try connReader.readUntilDelimiterAlloc(allocator, '\n', 1024);
        dprint("Bruh\n", .{});
        dprint("{}\r\n", .{msg.*});
        allocator.destroy(msg);
    }
}
