#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#include "read_file.c"
#include "buffer.c"

int diff(int a, int b) {
    if (a > b) {
        return a - b;
    } else {
        return b - a;
    }
}

typedef struct {
    int * items;
    int cap;
    int len;
    int i;
    int skip_i;
} IntSkipArray;

void IntSkipArray_add(IntSkipArray * array, int value) {
    assert(array->len < array->cap);
    array->items[array->len] = value;
    array->len += 1;
}

int IntSkipArray_next(IntSkipArray * array, bool * end) {
    if (array->i == array->skip_i) {
        array->i += 1;
    }
    if (array->i >= array->len) {
        *end = true;
        return 0;
    }
    *end = false;
    int result = array->items[array->i];
    array->i += 1;
    return result;
}

void IntSkipArray_reset(IntSkipArray * array, bool * done) {
    array->skip_i += 1;
    if (array->skip_i >= array->len) {
        *done = true;
        return;
    }
    *done = false;
    array->i = 0;
    return;
}


int main(int argc, char*argv[]) {
    char * filename = "input_2_1_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    FileReadResult file_result = read_entire_file(filename);
    if (!file_result.ok) {
        return 1;
    }

    Buffer buf = {
        .data = file_result.buffer,
        .len = file_result.length,
        .i = 0,
    };

    // one report per line
    // each report is a list of number called levels
    // (space separated)
    
    // which reports are safe?
    int safe_reports = 0;

    // must be gradually increasing or gradually decreasing
    // all increasing or all decreasing
    // differ by at least one and at most three
    while (buf.i < buf.len) {
        
        bool ok = false;
        int n_prev = buffer_read_next_number(&buf, &ok);
        if (!ok) {
            goto nextline;
        }
        int n = buffer_read_next_number(&buf, &ok);
        if (!ok) {
            goto nextline;
        }
        bool increasing = n > n_prev;

        bool valid = true;
        
        while (ok) {
            if (increasing && n < n_prev) {
                valid = false;
                break;
            }
            if (!increasing && n > n_prev) {
                valid = false;
                break;
            }
            int d = diff(n, n_prev);
            if (d < 1 || d > 3) {
                valid = false;
                break;
            }
            
            n_prev = n;
            n = buffer_read_next_number(&buf, &ok);
        }

        if (valid) {
            safe_reports += 1;
        }
        
        nextline:
        buffer_skip_to_next_line(&buf);
    }

    printf("%d\n", safe_reports);
    assert(safe_reports == 246);

    // part 2

    // if one level can be skipped and it's safe, then it counts as safe
    safe_reports = 0;
    buf.i = 0;
    
    while (buf.i < buf.len) {

        int int_backing_array[16];
        IntSkipArray int_skip_array = {
            .items = int_backing_array,
            .cap = 16,
            .len = 0,
            .i = 0,
            .skip_i = -1
        };

        bool ok = true;
        while (ok) {
            int number = buffer_read_next_number(&buf, &ok);
            if (ok) {
                IntSkipArray_add(&int_skip_array, number);
            }
        }

        bool at_least_one_is_valid = false;

        bool done_with_skips = false;
        while (!done_with_skips) {
        
            bool end = false;
            bool valid = true;
            int n_prev = IntSkipArray_next(&int_skip_array, &end);
            if (end) {
                valid = false;
                goto skipreset;
            }
            int n = IntSkipArray_next(&int_skip_array, &end);
            if (end) {
                valid = false;
                goto skipreset;
            }
            bool increasing = n > n_prev;

            while (!end) {
                if (increasing && n < n_prev) {
                    valid = false;
                    break;
                }
                if (!increasing && n > n_prev) {
                    valid = false;
                    break;
                }
                int d = diff(n, n_prev);
                if (d < 1 || d > 3) {
                    valid = false;
                    break;
                }
                n_prev = n;
                n = IntSkipArray_next(&int_skip_array, &end);
            }

            if (valid) {
                at_least_one_is_valid = true;
                break;
            }

            skipreset:
            IntSkipArray_reset(&int_skip_array, &done_with_skips);
            
        }
        if (at_least_one_is_valid) {
            safe_reports += 1;
        }
        
        buffer_skip_to_next_line(&buf);
    }

    printf("%d\n", safe_reports);
    assert(safe_reports == 318);
    
    return 0;
    
}
