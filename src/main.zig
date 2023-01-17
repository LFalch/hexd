const std = @import("std");

const BufWriter = std.io.BufferedWriter(4096, std.fs.File.Writer);

pub inline fn printspaces(stdout: BufWriter.Writer, spaces: u6) BufWriter.Error!void {
    const length = std.math.maxInt(u6)+1;
    const space = " " ** length;

    try stdout.writeAll(space[0..spaces]);
}

pub inline fn errPrint(comptime format: []const u8, args: anytype) std.fs.File.WriteError!void {
    return std.io.getStdErr().writer().print(format, args);
}

pub fn main() !u8 {
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();
    // using this variant for better portability (e.g. Windows needs this to convert args from UTF-16 to UTF-8)
    // platforms with OS strings as UTF-8 will not use the allocator
    var args = try std.process.argsWithAllocator(alloc.allocator());
    defer args.deinit();

    const program = args.next() orelse return error.NoProgramArg;
    var inputPath = args.next();

    if (args.skip()) {
        try errPrint("Usage: {s} [file]\n\tReads from STDIN if no argument is given.\n", .{program});
        return 1;
    }

    const ends = [8][]const u8{
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        "  ",
    };
    const file = if (inputPath) |path|
        std.fs.cwd().openFile(path, .{}) catch |err| {
            try errPrint("Could not open file: {s}\n", .{@errorName(err)});
            return 1;
        }
    else std.io.getStdIn();
    defer file.close();
    var br = std.io.bufferedReader(file.reader());
    const reader = br.reader();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer bw.flush() catch {};
    const stdout = bw.writer();

    var bytes: [16]u8 = undefined;
    var index: usize = 0;
    var read: usize = undefined;

    while (true) : (index += read) {
        read = reader.readAll(&bytes) catch |err| {
            try errPrint("Could not read file: {s}\n", .{@errorName(err)});
            return 1;
        };

        if (read == 0) break;

        try stdout.print("{x:0<8}  ", .{index});
        {
            var i: usize = 0;
            while (i < read) : (i += 1) {
                try stdout.print("{x:0<2}{s}", .{bytes[i], ends[i & 7]});
            }
        }
        if (read != 16) {
            const numSpaces = @intCast(u6, 1 + (16 - read) * 3 + @divTrunc(15 - read, 8));
            try printspaces(stdout, numSpaces);
        }
        try stdout.print("|", .{});
        {
            var i: usize = 0;
            while (i < read) : (i += 1) {
                var c: u8 = bytes[i];
                if (c < 0x20 or c >= 0x7f) {
                    try stdout.print(".", .{});
                } else {
                    try stdout.print("{c}", .{c});
                }
            }
        }
        try stdout.print("|\n", .{});
    }
    try stdout.print("{x:0<8}\n", .{index});

    return 0;
}
