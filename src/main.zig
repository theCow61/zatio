const std = @import("std");
const server = @import("server.zig");
const client = @import("client.zig");
const Allocater = std.mem.Allocator;
const print = std.debug.print;
pub const io_mode = .evented;

//fn server(ip: [4]u8, port: u16) !void {
//    var listener = std.net.StreamServer.init(.{});
//    defer listener.deinit();
//    listener.listen(std.net.Address.initIp4(ip, port)) catch |err| {
//        print("err: {}\n", .{err});
//        return err;
//    };
//    const connection = listener.accept() catch |err| {
//        print("err: {}.\n", .{err});
//        return err;
//    };
//    print("{} has connected.\n", .{connection.address});
//    const connFile = connection.file;
//    defer connFile.close();
//    const connWriter = connFile.writer();
//    const connReader = connFile.reader();
//    // Cant test if this would work or not with the catch, want it to not matter if no one at other end.
//    //connFile.writeAll("yoo\n") catch {};
//    //connWriter.writeAll("yoo\n") catch {};
//    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//    defer arena.deinit();
//    const allocater = &arena.allocator;
//    const stdinFile = std.io.getStdIn();
//    defer stdinFile.close();
//    const stdin = stdinFile.reader();
//    print("{}\n", .{@typeName(@TypeOf(connReader))});
//    var frameGetMessg = async getMessg(allocater, connReader);

//    connWriter.writeAll("yootest\n") catch {};
//    while (true) {
//        //const msg = stdout.readToEndAlloc(allocater, 1024) catch |err| {
//        //   print("Message too long, didn't send.\n", .{});
//        //};
//        var msg: []u8 = undefined;
//        //if (stdin.readToEndAlloc(allocater, 1024)) |tmsg| {
//        //msg = tmsg;
//        //} else |_| {
//        //continue;
//        //}
//        if (stdin.readUntilDelimiterAlloc(allocater, '\n', 1024)) |tmsg| {
//            msg = tmsg;
//        } else |_| {
//            print("message too long, didn't send.\n", .{});
//            continue;
//        }
//        //print("{}\n", .{msg});
//        //connFile.writeAll(msg) catch {};
//        connWriter.print("{s}\r\n", .{msg}) catch {};
//        defer allocater.free(msg);
//    }
//    try await frameGetMessg;
//}

//fn serv(ip: [4]u8, port: u16) !void {
//   var listener = std.net.StreamServer.init(.{});
//  defer listener.deinit();
// listener.listen(std.net.Address.parseIp4("0.0.0.0", 42069) catch |err| {
//    print("err: {}\n", .{err});
//   return err;
//}) catch |err| {
//   print("err: {}\n", .{err});
//  return err;
//};
//while (true) {
//if (listener.accept()) |connection| {} else |_| {
//   continue;
//}
//}
//}

// fn getMessg(allocater: *Allocater, connReader: std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read)) !void {
//     while (true) {
//         if (connReader.readUntilDelimiterAlloc(allocater, '\n', 1024)) |msg| {
//             print("{}\r\n", .{msg});
//         } else |_| {
//             continue;
//         }
//     }
// }

// fn client(ip: [4]u8, port: u16) !void {}

pub fn main() !void {
    //std.log.info("All your codebase are belong to us.", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = &arena.allocator;
    //arg0 = if (arg0) |arg| arg else unreachable;
    var args = std.process.ArgIterator.init();
    defer args.deinit();
    _ = args.skip();
    const arg0 = if (args.next(alloc)) |arg| arg catch unreachable else {
        print("format: zatio [server/client]\n", .{});
        return;
    };
    //var string: [6]u8 = "server";
    //if (&arg0[0..:0] == "server") {}
    //const br = "hi";
    if (std.mem.eql(u8, try std.ascii.allocLowerString(alloc, arg0), "server")) {
        const ip: [4]u8 = [4]u8{ 0, 0, 0, 0 };
        //try server(ip, 42069);
        try server.start(ip, 42069);
        //try serv(ip, 42069);
    } else if (std.mem.eql(u8, try std.ascii.allocLowerString(alloc, arg0), "client")) {
        // try client([4]u8{ 127, 0, 0, 1 }, 42069);
        const ip = "0.0.0.0";
        try client.start(ip, 42069);
    } else {
        print("format: zatio [server/client]\n", .{});
    }
    print("\n", .{});
}
