#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include "read_file.c"
#include "buffer.c"

void buffer_chomp(Buffer * buf, char ch_to_chomp, bool * ok) {
    if (buf->i >= buf->len) {
        *ok = false;
        return;
    }
    char ch = buf->data[buf->i];
    
    buf->i += 1;
    *ok = ch == ch_to_chomp;
    return;
}

void chomp_fluff(Buffer * buf, bool * fluff) {
    if (buf->i >= buf->len) {
        *fluff = false;
        return;
    }

    char ch = buf->data[buf->i];
    if (ch == 'm') {
        *fluff = false;
        return;
    }
    
    buf->i += 1;
    *fluff = true;
    return;
}
void chomp_all_fluff(Buffer * buf) {
    bool fluff = true;
    while (fluff) {
        chomp_fluff(buf, &fluff);
    }
}

int buffer_next_multiply_solution(Buffer * buf) {
    chomp_all_fluff(buf);
    
    bool ok = true;
    buffer_chomp(buf, 'm', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, 'u', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, 'l', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, '(', &ok); if (!ok) { return 0; }
    int n1 = buffer_read_number(buf, &ok); if (!ok) { return 0; }
    buffer_chomp(buf, ',', &ok); if (!ok) { return 0; }
    int n2 = buffer_read_number(buf, &ok); if (!ok) { return 0; }
    buffer_chomp(buf, ')', &ok); if (!ok) { return 0; }
    return n1 * n2;
}

int chomp_multiply_solution(Buffer * buf) {
    bool ok = true;
    buffer_chomp(buf, 'm', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, 'u', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, 'l', &ok); if (!ok) { return 0; }
    buffer_chomp(buf, '(', &ok); if (!ok) { return 0; }
    int n1 = buffer_read_number(buf, &ok); if (!ok) { return 0; }
    buffer_chomp(buf, ',', &ok); if (!ok) { return 0; }
    int n2 = buffer_read_number(buf, &ok); if (!ok) { return 0; }
    buffer_chomp(buf, ')', &ok); if (!ok) { return 0; }
    return n1 * n2;
}

void chomp_fluff_d_m(Buffer * buf, bool * fluff) {
    if (buf->i >= buf->len) {
        *fluff = false;
        return;
    }

    char ch = buf->data[buf->i];
    if (ch == 'm' || ch == 'd') {
        *fluff = false;
        return;
    }
    
    buf->i += 1;
    *fluff = true;
    return;
}
void chomp_fluff_d(Buffer * buf, bool * fluff) {
    if (buf->i >= buf->len) {
        *fluff = false;
        return;
    }

    char ch = buf->data[buf->i];
    if (ch == 'd') {
        *fluff = false;
        return;
    }
    
    buf->i += 1;
    *fluff = true;
    return;
}

bool buffer_is_dont_next(Buffer * buf) {
    bool ok = false;
    ok = buffer_peek_i(buf, 0) == 'd'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 1) == 'o'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 2) == 'n'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 3) ==  '\''; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 4) == 't'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 5) == '('; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 6) == ')'; if (!ok) { return false; };
    return true;
}
bool buffer_is_do_next(Buffer * buf) {
    bool ok = false;
    ok = buffer_peek_i(buf, 0) == 'd'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 1) == 'o'; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 2) == '('; if (!ok) { return false; };
    ok = buffer_peek_i(buf, 3) == ')'; if (!ok) { return false; };
    return true;
}
void _buffer_peek_number(Buffer * buf, int off, bool * ok, int * len) {
    *len = 0;
    *ok = false;
    int i = 0;;
    for (i = off; is_digit(buffer_peek_i(buf, i)); i += 1) {
        *ok = true;
    }
    *len = i - off;
}
bool buffer_is_mul_next(Buffer * buf) {
    bool ok = true;
    int i = 0;
    int len = 0;
    ok = buffer_peek_i(buf, i) == 'm'; i++; if (!ok) { return 0; }
    ok = buffer_peek_i(buf, i) == 'u'; i++; if (!ok) { return 0; }
    ok = buffer_peek_i(buf, i) == 'l'; i++; if (!ok) { return 0; }
    ok = buffer_peek_i(buf, i) == '('; i++; if (!ok) { return 0; }
    _buffer_peek_number(buf, i, &ok, &len); i += len; if (!ok) { return 0; }
    ok = buffer_peek_i(buf, i) == ','; i++; if (!ok) { return 0; }
    _buffer_peek_number(buf, i, &ok, &len); i += len; if (!ok) { return 0; }
    ok = buffer_peek_i(buf, i) == ')'; i++; if (!ok) { return 0; }
    return true;
}

void chomp_fluff_except_dont_m(Buffer * buf, bool * is_dont) {
    bool fluff = true;
    
    while (fluff) {
        chomp_fluff_d_m(buf, &fluff);
        if (buffer_is_dont_next(buf)) {
            *is_dont = true;
            return;
        } 
        if (buffer_peek(buf) == 'm') {
            *is_dont = false;
            return;
        } else {
            // skip past d of do() so chomp_fluff_d_m can continue
            buf->i += 1;
            continue;
        }
    }
}

void chomp_dont(Buffer * buf) {
    // don't()
    buf->i += 7;
}

void chomp_until_do(Buffer * buf) {
    bool fluff = true;
    while (fluff) {
        chomp_fluff_d(buf, &fluff);
        if (buffer_is_do_next(buf)) {
            return;
        } else {
            buf->i += 1;
            continue;
        }
    }
}

void chomp_do(Buffer * buf) {
    // do()
    buf->i += 4;
}

int buffer_next_multiply_solution_with_dos(Buffer * buf, bool * do_mode) {
    char * debug_line = &buf->data[buf->i];
    if (*do_mode) {
        // can ignore do()
        // search for next don't()
        // or next multiply solution
        bool is_dont = false;
        chomp_fluff_except_dont_m(buf, &is_dont);
        debug_line = &buf->data[buf->i];
        if (is_dont) {
            chomp_dont(buf);
            debug_line = &buf->data[buf->i];
            *do_mode = false;
            return 0;
        } else {
            return chomp_multiply_solution(buf);
        }
    } else {
        // can ignore don't()
        // search for next do()
        // ignore multiply solution
        debug_line = &buf->data[buf->i];
        chomp_until_do(buf);
        debug_line = &buf->data[buf->i];
        chomp_do(buf);
        debug_line = &buf->data[buf->i];
        *do_mode = true;
        return 0;
    }
}

int main(int argc, char*argv[]) {
    char * filename = "input_3_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    FileReadResult file_read_result = read_entire_file(filename);
    if (!file_read_result.ok) {
        return 1;
    }
    Buffer buf = {
        .data = file_read_result.buffer,
        .len = file_read_result.length,
        .i = 0,
    };

    // part 1
    // read mul(12,321) instructions only (no spaces)
    // return sum of these multiply instructions
    int part1_result = 0;
    while (buf.i < buf.len) {
        int next_multiply_solution = buffer_next_multiply_solution(&buf);
        part1_result += next_multiply_solution;
    }
    printf("%d\n", part1_result);
    assert(part1_result == 159833790);

    // part 2
    // handle do() and don't() instructions
    int part2_result = 0;
    bool do_mode = true;
    buf.i = 0;
    char * debug_line = &buf.data[buf.i];
    while (buf.i < buf.len) {
        // int next_multiply_solution = buffer_next_multiply_solution_with_dos(&buf, &do_mode);
        // part2_result += next_multiply_solution;
        debug_line = &buf.data[buf.i];

        if (do_mode) {
            bool dont_next = buffer_is_dont_next(&buf);
            if (dont_next) {
                do_mode = false;
                buf.i += 7;
                continue;
            }
            bool mul_next = buffer_is_mul_next(&buf);
            if (mul_next) {
                int mul = chomp_multiply_solution(&buf);
                part2_result += mul;
            } else {
                buf.i += 1;
            }
        } else {
            bool do_next = buffer_is_do_next(&buf);
            if (do_next) {
                do_mode = true;
                buf.i += 4;
            } else {
                buf.i += 1;
            }
        }
    }
    printf("%d\n", part2_result);
    assert(part2_result == 89349241);
    return 0;
}
