#include <stdbool.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "read_file.c"
#include "buffer.c"

typedef struct {
    int x;
    int y;
} Pos;

typedef enum {
    UP,
    DN,
    LF,
    RT,
} Dir;

typedef struct {
    Buffer buf;
    Pos guard;
    Dir facing;
    int rows;
    int cols;
    int newline_size;
} Map;

Map Map_new(Buffer source_buf) {
    // copy buffer data
    Buffer new_buf = {.i=0, .len=source_buf.len};
    char * new_data = malloc(source_buf.len);
    memcpy(new_data, source_buf.data, source_buf.len);
    new_buf.data = new_data;
    
    Map map = {.buf = new_buf};
    Buffer buf = map.buf;
    
    buffer_skip_to_next_line(&buf);
    if (buffer_peek_i(buf, -1) == '\n' && buffer_peek_i(buf, -2) == '\r') {
        map.newline_size = 2;
    } else {
        map.newline_size = 1;
    }
    map.cols = buf.i - 2;
    // we already have 1 row, but there will be an extra run of this loop
    // at the end of the file, so start at 0 to account for this.
    for (map.rows = 0; buf.i < buf.len; map.rows += 1) {
        buffer_skip_to_next_line(&buf);
    }
    buf.i = 0;

    map.guard.x = -1;
    map.guard.y = -1;
    for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(buf);
        if (ch == '^') {
            map.guard.y = buf.i / (map.rows + map.newline_size);
            map.guard.x = buf.i % (map.rows + map.newline_size);
            map.facing = UP; 
            break;
        }
    }
    assert(map.guard.x != -1 && map.guard.y != -1);
    return map;
}

void Map_advance(Map * map, bool * done, bool * loop) {
    
    // first look in direction facing until '#' or edge
    int increment = 0;
    switch (map->facing) {
        case UP: increment = (-map->cols - map->newline_size); break; 
        case DN: increment = ( map->cols + map->newline_size); break; 
        case LF: increment =  -1;                              break; 
        case RT: increment =   1;                              break; 
    }
    assert(increment != 0);
    int x_increment = 0;
    int y_increment = 0;
    switch (map->facing) {
        case UP: y_increment = -1; break;
        case DN: y_increment =  1; break;
        case LF: x_increment = -1; break;
        case RT: x_increment =  1; break;
    }
    assert(x_increment != 0 || y_increment != 0);

    int x = map->guard.x;
    int y = map->guard.y;

    while (true) {
        map->buf.i = (y * (map->cols + map->newline_size)) + x;
        char current = buffer_peek(map->buf);
        if (current == '.') {
            map->buf.data[map->buf.i] = 'X';
        }
        char ch = buffer_peek_i(map->buf, increment);
        if (ch == '#' || ch == 'O') {
            map->buf.data[map->buf.i] = '+';
            *done = false;
            break;
        }
        if (ch == 0 || ch == '\r' || ch == '\n') {
            *done = true;
            break;
        }
        
        if (ch == '+') {
            // check for next one in the same dir
            char ch2 = buffer_peek_i(map->buf, increment*2);
            if (ch2 == '#' || ch2 == 'O') {
                *loop = true;
                *done = true;
                break;
            }
        }
        x += x_increment;
        y += y_increment;
    }
    
    // move guard to new pos
    map->guard.x = x;
    map->guard.y = y;
    
    // switch facing (90 degrees)
    Dir new_facing;
    switch (map->facing) {
        case UP: new_facing = RT; break;
        case DN: new_facing = LF; break;
        case LF: new_facing = UP; break;
        case RT: new_facing = DN; break;
    }
    map->facing = new_facing;
}

int Map_solve(Map * map) {
    bool done = false;
    bool loop = false;
    while (!done) {
        Map_advance(map, &done, &loop);
        if (loop) {
            done = true;
        }
        assert(!loop);
    }

    int visited = 0;
    Buffer buf = map->buf;
    for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(buf);
        if (ch == 'X' || ch == '+' || ch == '^') {
            visited += 1;
        }
    }

    // reset guard location and facing
    map->guard.x = -1;
    map->guard.y = -1;
    for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(buf);
        if (ch == '^') {
            map->guard.y = buf.i / (map->rows + map->newline_size);
            map->guard.x = buf.i % (map->rows + map->newline_size);
            map->facing = UP; 
            break;
        }
    }
    assert(map->guard.x != -1 && map->guard.y != -1);
    
    return visited;
}

int Map_solve2(Map src_map, Map * map) {

    int options = 0;
    
    // src_map must be solved for part 1 first

    // for every 'X' or '+', try placing an obstical there and then
    // solving to determine if a loop exists
    for (src_map.buf.i = 0; src_map.buf.i < src_map.buf.len; src_map.buf.i += 1) {
        char ch = buffer_peek(src_map.buf);
        if (ch != 'X' && ch != '+') {
            continue;
        }

        // set the obstacle
        map->buf.data[src_map.buf.i] = 'O';

        // int y = src_map.buf.i / (src_map.rows + src_map.newline_size);
        // int x = src_map.buf.i % (src_map.rows + src_map.newline_size);
        // if (y == 6 && x == 3) {
        //     options += 0;
        // }

        bool done = false;
        bool loop = false;
        while (!done) {
            Map_advance(map, &done, &loop);
            if (loop) {
                options += 1;
                break;
            }
        }
        
        // unset the obstacle
        map->buf.data[src_map.buf.i] = '.';
        
        // after each one, reset map2
        for (map->buf.i = 0; map->buf.i < map->buf.len; map->buf.i += 1) {
            char ch = buffer_peek(map->buf);
            if (ch == 'X' || ch == '+') {
                map->buf.data[map->buf.i] = '.';
            }
        }
        map->facing = UP;
        map->guard = src_map.guard;
    }

    return options;
}

int main(int argc, char * argv[]) {
    char * filename = "input_6_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    Buffer buf = { .i = 0 };
    bool ok = false;
    buf.data = read_entire_file2(filename, &ok, &buf.len);
    if (!ok) {
        fprintf(stderr, "Failed to read file: %s\n", filename);
        return 1;
    }

    // get info rows, columns, and chars per newline (\r\n vs \n)
    Map map = Map_new(buf);

    int part1_result = 0;
    part1_result = Map_solve(&map);

    printf("%d\n", part1_result);

    Map map2 = Map_new(buf);
    int part2_result = 0;
    part2_result = Map_solve2(map, &map2);
    
    printf("%d\n", part2_result);

    return 0;
}
