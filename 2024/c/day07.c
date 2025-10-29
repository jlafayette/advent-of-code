#include <stdbool.h>
#include <assert.h>
#include <stdio.h>
#include <inttypes.h>

#include "read_file.c"
#include "buffer.c"


// --- IntDynamicArray

typedef struct {
    int * items;
    int len;
    int cap;
} IntDynamicArray;

IntDynamicArray IntDynamicArray_new(int cap) {
    IntDynamicArray array;
    array.len = 0;
    array.cap = 0;
    array.items = calloc(cap, sizeof(int));
    if (array.items) {
        array.cap = cap;
    }
    assert(array.cap == cap);
    return array;
}

bool IntDynamicArray_append(IntDynamicArray * array, int item) {
    assert(array->len < array->cap);
    if (array->len < array->cap) {
        array->items[array->len] = item;
        array->len += 1;
        return true;
    }
    return false;
}

void IntDynamicArray_clear(IntDynamicArray * array) {
    array->len = 0;
}


// --- Equation

typedef struct {
    uint64_t test_value;
    IntDynamicArray numbers;
} Equation;

bool _get_bit(int n, int k) {
    int max = 1 << k;
    int masked_n = n & max;
    return masked_n >> k;
}

/*
int i_pow(int base, int exponent) {
    return (int)pow((double)base, (double)exponent);
}
*/
int i_pow(int base, int exp) {
    int r = base;
    for (int i = 0; i < exp-1; i += 1) {
        r = r * base;
    };
    return r;
}
uint64_t u64_pow(uint64_t base, uint64_t exp) {
    uint64_t r = base;
    for (uint64_t i = 0; i < exp-1; i += 1) {
        r = r * base;
    };
    return r;
}

uint64_t Equation_solve(Equation eq) {
    // iterate over all possible +/* possibilties
    
    // 292: 11 6 16 20
    // 11+6+16+20
    // 11+6+16*20
    //
    // c for combination
    int max_c = i_pow(2, eq.numbers.len-1);
    for (int c = 0; c < max_c; c += 1) {
        // a single combination
        uint64_t a = 0; // a for answer
        for (int i = 0; i < eq.numbers.len; i += 1) {
            uint64_t n = (uint64_t)eq.numbers.items[i];
            if (i == 0) {
                a = n;
                continue;
            }
            // remaining positions
            // 292: 11 6 16 20
            //   i:  0 1  2  3
            //  rp:  _ 2  1  0
            int rp = eq.numbers.len - i - 1;
            bool mul = _get_bit(c, rp);
            if (mul) {
                a = a * n;
            } else {
                a = a + n;
            }
            if (a > eq.test_value) {
                break;
            }
        }
        if (a == eq.test_value) {
            return a;
        }
    }
    
    // no solutions
    return 0;
}

typedef struct {
    int gap_count;
    int i;
    int j;
    int div;
    int r;
} Gen3;

Gen3 Gen3_new(int gap_count) {
    Gen3 g = {
        .gap_count = gap_count,
        .i = 0,
        .j = 0,
        .div = i_pow(3, gap_count - 1),
        .r = 0,
    };
    return g;
}

int Gen3_next(Gen3 * g) {
    if (g->gap_count == 1) {
        int a = g->i;
        g->i += 1;
        return a;
    }
    if (g->j >= g->gap_count) {
        g->j = 0;
        g->i += 1;
        g->r = g->i;
        g->div = i_pow(3, g->gap_count - 1);
    }

    int a = g->r / g->div;
    g->r = g->r - (a * g->div);
    g->div = g->div / 3;
    g->j += 1;
    return a;
}

uint64_t concat(uint64_t a, uint64_t b) {
    uint64_t len_b = 1;
    uint64_t r = 10;
    while (true) {
        if ((b % r) == b) {
            break;
        }
        r = r * 10;
        len_b += 1;
    }
    uint64_t result = 0;
    result = (a * u64_pow(10, len_b)) + b;
    return result;
}

uint64_t Equation_solve2(Equation eq) {
    // iterate over all possible +/*/concat possibilties
    
    // c for combination
    Gen3 g3 = Gen3_new(eq.numbers.len-1);
    int max_c = i_pow(3, eq.numbers.len-1);
    for (int c = 0; c < max_c; c += 1) {
        // a single combination
        uint64_t a = 0; // a for answer
        for (int i = 0; i < eq.numbers.len; i += 1) {
            uint64_t n = (uint64_t)eq.numbers.items[i];
            if (i == 0) {
                a = n;
                continue;
            }
            int op = Gen3_next(&g3);
            switch (op) {
                case 0: a = a + n; break;
                case 1: a = a * n; break;
                case 2: a = concat(a, n); break;
            }
            if (a > eq.test_value) {
                break;
            }
        }
        if (a == eq.test_value) {
            return a;
        }
    }
    // no solutions
    return 0;
}

// --- EquationArray

typedef struct {
    Equation * items;
    int len;
    int cap;
} EquationArray;

EquationArray EquationArray_new(int cap) {
    EquationArray array;
    array.len = 0;
    array.cap = 0;
    array.items = calloc(cap, sizeof(Equation));
    if (array.items) {
        array.cap = cap;
    }
    assert(array.cap == cap);
    return array;
}

bool EquationArray_append(EquationArray * array, Equation item) {
    assert(array->len < array->cap);
    if (array->len < array->cap) {
        array->items[array->len] = item;
        array->len += 1;
        return true;
    }
    return false;
}

int main(int argc, char * argv[]) {
    char * filename = "input_7_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    Buffer buf = {.i=0};
    bool ok = false;
    buf.data = read_entire_file2(filename, &ok, &buf.len);
    if (!ok) {
        return 1;
    }

    // get required info for parsing
    int equation_count = 0;
    int highest_number_count = 0;
    for (buf.i = 0; buf.i < buf.len; buffer_skip_to_next_line(&buf)) {
        bool ok = false;
        buffer_read_u64(&buf, &ok); if (!ok) { break; }
        buf.i += 2;
        int number_count = 0;
        while (true) {
            if (buffer_peek(buf) == ' ') {
                buf.i += 1;
            }
            buffer_read_number(&buf, &ok);
            if (ok) {
                number_count += 1;
            } else {
                break;
            }
        }
        if (number_count > highest_number_count) {
            highest_number_count = number_count;
        }
        equation_count += 1;
    }
    assert(equation_count > 0);
    assert(highest_number_count >= 2);

    // actual parse
    EquationArray equations = EquationArray_new(equation_count);
    for (buf.i = 0; buf.i < buf.len; buffer_skip_to_next_line(&buf)) {
        bool ok = false;
        uint64_t n = buffer_read_u64(&buf, &ok); if (!ok) { break; }
        Equation eq = {
            .test_value = n,
            .numbers = IntDynamicArray_new(highest_number_count)
        };
        buf.i += 2;
        while (true) {
            if (buffer_peek(buf) == ' ') {
                buf.i += 1;
            }
            n = buffer_read_number(&buf, &ok); if (!ok) { break; }
            IntDynamicArray_append(&eq.numbers, n);
        }
        assert(eq.numbers.len >= 2);
        EquationArray_append(&equations, eq);
    }

    uint64_t part1_result = 0;
    for (int i = 0; i < equations.len; i += 1) {
         uint64_t s = Equation_solve(equations.items[i]);
         if (s > 0) {
             part1_result += s;
         }
    }
    
    // 21572148763543  correct
    printf("%" PRIu64 "\n", part1_result);
    
    uint64_t part2_result = 0;
    for (int i = 0; i < equations.len; i += 1) {
         uint64_t s = Equation_solve2(equations.items[i]);
         if (s > 0) {
             part2_result += s;
         }
    }

    // 562028995691762 (too low)
    printf("%" PRIu64 "\n", part2_result);
    
    return 0;
}
