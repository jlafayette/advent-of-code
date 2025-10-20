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
            if (n == n_prev) {
                // invalid, must increase or decrease by at least 1
                valid = false;
                break;
            }
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
    
    return 0;
    
}
