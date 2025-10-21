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
void chomp_fluff_2(Buffer * buf, bool * fluff) {
    if (buf->i >= buf->len) {
        *fluff = false;
        return;
    }
    char ch = buffer_peek(buf);
    if (ch == 'm' || ch == 'd') {
        *fluff = false;
        return;
    }
    buf->i += 1;
    *fluff = true;
    return;
}
int chomp_until_d_or_m(Buffer * buf) {
    bool fluff = true;
    int amount_chomped = 0;
    while (fluff) {
        chomp_fluff_2(buf, &fluff);
        if (fluff) {
            amount_chomped += 1;
        }
    }
    return amount_chomped;
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
    while (buf.i < buf.len) {
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
                chomp_until_d_or_m(&buf);
            }
        } else {
            bool do_next = buffer_is_do_next(&buf);
            if (do_next) {
                do_mode = true;
                buf.i += 4;
            } else {
                buf.i += 1;
                chomp_until_d_or_m(&buf);
            }
        }
    }
    printf("%d\n", part2_result);
    assert(part2_result == 89349241);
    return 0;
}
