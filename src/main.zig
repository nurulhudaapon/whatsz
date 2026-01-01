const std = @import("std");
const zqlite = @import("zqlite");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    _ = allocator;

    std.debug.print("Hello, World!\n", .{});

    // good idea to pass EXResCode to get extended result codes (more detailed error codes)
    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(".zig-cache/tmp/test.sqlite", flags);
    defer conn.close();

    try conn.exec("create table if not exists test (name text)", .{});
    try conn.exec("insert into test (name) values (?1), (?2)", .{ "Leto", "Ghanima" });

    {
        if (try conn.row("select * from test order by name limit 1", .{})) |row| {
            defer row.deinit();
            std.debug.print("name: {s}\n", .{row.text(0)});
        }
    }

    {
        var rows = try conn.rows("select * from test order by name", .{});
        defer rows.deinit();
        while (rows.next()) |row| {
            std.debug.print("name: {s}\n", .{row.text(0)});
        }
        if (rows.err) |err| return err;
    }
}
