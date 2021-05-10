const std = @import("std");
const Allocater = std.mem.Allocator;
const print = std.debug.print;
pub const io_mode = .evented;

// After user leaves, free the users memory off the heap AND TAKE THEIR OBJECT OUT OF HASHMAP

const Room = struct {
    //connected: std.AutoHashMap(*const std.net.StreamServer.Connection, void),
    connected: std.AutoHashMap(*User, void),

    fn broadcast(self: *Room, toBC: []const u8, user: *User) void {
        var iterDconnected = self.connected.iterator();
        while (iterDconnected.next()) |sConnected| {
            //print("{}\n", .{sConnected.key});
            const connectedKey = sConnected.key;
            if (connectedKey == user) continue;
            const connectionWriter = connectedKey.connection.file.writer();
            //const msg = toBC[user.name.len + 2 ..];
            connectionWriter.print("\n\x1b[32;1m{}:\x1b[0m {}\r\n", .{ user.name, toBC }) catch {
                _ = self.connected.remove(connectedKey);
            };
        }
    }

    fn removeUser(self: *Room, user: *User) void {
        _ = self.connected.remove(user);
        var iterDconnected = self.connected.iterator();
        while (iterDconnected.next()) |sConnected| {
            const connectionWriter = sConnected.key.connection.file.writer();
            connectionWriter.print("\n\x1b[35;2m{} has left.\x1b[0m\r\n", .{user.name}) catch {
                _ = self.connected.remove(sConnected.key);
            };
        }
    }

    //fn handle(self: *Room, allocator: *Allocater) void {
    //   var iterDconnected = self.connected.iterator();
    //  while (true) {
    //     while (iterDconnected.next()) |sConnected| {
    //        const connectionReader = sConnected.key.file.reader();
    //       if (connectionReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |msg| {
    //          self.broadcast(msg);
    //     } else |_| {
    //        continue;
    //   }
    //}
    //}
    //}
};

const User = struct {
    connection: std.net.StreamServer.Connection,
    handleFrame: @Frame(handle),
    name: []const u8,

    fn handle(self: *User, allocator: *Allocater, room: *Room) void {
        defer allocator.destroy(self);
        const connectionReader = self.connection.file.reader();
        const connectionWriter = self.connection.file.writer();
        self.getInfo(allocator, &connectionReader, &connectionWriter);
        // print("{}\n", .{@typeName(@TypeOf(connectionReader))});
        while (true) {
            connectionWriter.print("\x1b[31;1m{}(me):\x1b[0m ", .{self.name}) catch {};
            if (connectionReader.readUntilDelimiterAlloc(allocator, '\n', 1024)) |msg| {
                room.broadcast(msg, self);
            } else |_| {
                print("bruh1\n", .{});
                // FOUND IT, IT BE HERE
                room.removeUser(self);
                // defer allocator.destroy(self);
                return;
            }
        }
    }
    // std.io.reader.Reader(std.fs.file.File,std.os.ReadError,std.fs.file.File.read)
    fn getInfo(self: *User, allocator: *Allocater, connectionReader: *const std.io.Reader(std.fs.File, std.os.ReadError, std.fs.File.read), connectionWriter: *const std.io.Writer(std.fs.File, std.os.WriteError, std.fs.File.write)) void {
        connectionWriter.print("\x1b[33;1mIdentifier:\x1b[0m ", .{}) catch {};
        if (connectionReader.*.readUntilDelimiterAlloc(allocator, '\n', 12)) |name| {
            self.name = name;
        } else |_| {
            // Use error and see if error is of To Long error and say cant be over 12 then ask for input again.
        }
    }
};

pub fn start(ip: [4]u8, port: u16) !void {
    var listener = std.net.StreamServer.init(.{});
    defer listener.deinit();
    listener.listen(std.net.Address.parseIp4("0.0.0.0", 42069) catch |err| {
        print("err: {}\n", .{err});
        return err;
    }) catch |err| {
        print("err: {}\n", .{err});
        return err;
    };
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer gpa.deinit();
    defer arena.deinit();
    //const allocator = &gpa.allocator;
    const allocator = &arena.allocator;
    //var room = Room{ .connected = std.AutoHashMap(*const std.net.StreamServer.Connection, void).init(allocator) };
    var room = Room{ .connected = std.AutoHashMap(*User, void).init(allocator) };
    //var broadcastFrame: @Frame(Room.broadcast) = undefined;
    //print("YdOLO\n", .{});
    //var handleFrame: @Frame(User.handle) = undefined;
    //handleFrame = async room.handle(allocator);
    //print("YOLO\n", .{});
    while (true) {
        //if (listener.accept()) |connection| {
        //    //try room.connected.putNoClobber(&connection, {});
        //    ////try room.connected.put(&connection, {});
        //    const user = try allocator.create(User);
        //    //const user = User{ .connection = connection };
        //    user.* = User{ .connection = connection, .handleFrame = async user.handle(allocator, &room) };
        //    //handleFrame = async user.handle(allocator, &room);
        //    try room.connected.put(&user, {});
        //    //broadcastFrame = async room.broadcast("yee");
        //    //handleFrame = async room.handle(allocator);
        //} else |_| {
        //continue;
        //}
        const user = try allocator.create(User);
        user.* = User{ .connection = try listener.accept(), .handleFrame = async user.handle(allocator, &room), .name = "anon" };
        try room.connected.put(user, {});
    }
    //await broadcastFrame;
    //await handleFrame;
}
