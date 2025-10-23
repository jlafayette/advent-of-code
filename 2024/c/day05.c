#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "arrays.c"
#include "buffer.c"
#include "read_file.c"

bool buffer_after_two_new_lines(Buffer buf) {
    // \r\n
    bool with_carriage_return = 
            buffer_peek_i2(buf, -1) == '\n'
         && buffer_peek_i2(buf, -2) == '\r'
         && buffer_peek_i2(buf, -3) == '\n'
         && buffer_peek_i2(buf, -4) == '\r';
    // \n
    bool without =
            buffer_peek_i2(buf, -1) == '\n'
         && buffer_peek_i2(buf, -2) == '\n';
    return with_carriage_return || without;
}

bool IntArray_add_rule(IntArray array, int v1, int v2) {
    // start on left side with v1
    // iterate forward to check if it exists
    bool changes_made = false;
    bool v1_exists = false;
    int v1_index = 0;
    for (int i = 0; i < array.len; i += 1) {
        if (IntArray_get(array, i) == v1) {
            v1_exists = true;
            v1_index = i;
            break;
        }
    }
    // if it does, track index

    // if does not
    // add it to far left (move everything else 1 to the right)
    if (!v1_exists) {
        memmove(array.items+1, array.items, (array.len-1)*sizeof(int));
        IntArray_set(array, 0, v1);
        v1_exists = true;
        v1_index = 0;
        changes_made = true;
    }

    // start on right side for v2
    // iterate backward to check if it exists
    // stop if we hit [0]
    bool v2_exists = false;
    int v2_index = 0;
    int zero_index = array.len-1;
    for (int i = array.len-1; i >= 0; i -= 1) {
        int v = IntArray_get(array, i);
        if (v == 0) {
            zero_index = i;
        }
        if (v == v2) {
            v2_exists = true;
            v2_index = i;
            break;
        }
    }
    // if does not
    // add it to the far right (no shift)
    if (!v2_exists) {
        IntArray_set(array, zero_index, v2);
        v2_exists = true;
        v2_index = zero_index;
        zero_index += 1;
        changes_made = true;
    }

    // if it does
    // is it left of v1?
    // if so, then move it 1 after v1 (shift remaining to the right)
    assert(v1_index != v2_index);
    if (v1_index > v2_index) {
        // move v2 one after v1

        /*
            len=12
            v1=47, v2=61
            v1_index=3
            v2_index=0
        
                    0  1  2  3  4  5  6  7  8  9 10 11
                   61 97 75 47 53 29 13 __ __ __ __ __  
                   
                   // memmove
                   // dst =0 +v2_index
                   // src =1 +v2_index+1
                   // size=3 v1_index-v2_index                  
                    0  1  2  3  4  5  6  7  8  9 10 11
                   __ 97 75 47 53 29 13 __ __ __ __ __  
                      97 75 47 
                   97 75 47 
                   
                   // insert v2 at v1_index(3)
                    0  1  2  3  4  5  6  7  8  9 10 11
                   97 75 47 61 53 29 13 __ __ __ __ __  
            
            47|61  97 75 47 61 53 29 13 __ __ __ __ __ 
            
        */
        memmove(array.items+v2_index, array.items+v2_index+1, (v1_index-v2_index)*sizeof(int));
        IntArray_set(array, v1_index, v2);
        changes_made = true;
    }
    return changes_made;
}

int main(int argc, char * argv[]) {
    char * filename = "input_5_1_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    Buffer buf = { .i = 0 };
    bool ok = false;
    buf.data = read_entire_file2(filename, &ok, &buf.len);
    if (!ok) {
        return 1;
    }

    // part 1
    // determine if an update is in order based on rules
    // for ones in order, add up the middle numbers

    // count all
    for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
        if (buffer_after_two_new_lines(buf)) {
            break;
        }
    }
    // char * updates = &buf.data[buf.i];
    int updates_i = buf.i;
    int count = 0;
    for (buf.i = updates_i; buf.i < buf.len; buf.i += 1) {
        bool ok = false;
        int n = buffer_read_number(&buf, &ok);
        if (ok) {
            count += 1;
        }
    }
    
    IntArray array = IntArray_new(count);

    int changes = 1;
    int loop_count = 0;
    while (changes > 0 && loop_count < 50) {
        changes = 0;
        loop_count += 1;
        for (buf.i = 0; buf.i < updates_i; buffer_skip_to_next_line(&buf)) {
            bool ok = false;
            int v1 = buffer_read_number(&buf, &ok); if (!ok) { break; };
            buf.i += 1;  // discard '|'
            int v2 = buffer_read_number(&buf, &ok); if (!ok) { break; };
            bool change = IntArray_add_rule(array, v1, v2);
            if (change) {
                changes += 1;
            }
        }
    }
    
    // IntArray_add_rule(array, 47, 53); //        47 53
    // IntArray_add_rule(array, 97, 13); //     97 47 53 13
    // IntArray_add_rule(array, 97, 61); //     97 47 53 13 61
    // IntArray_add_rule(array, 97, 47); //     97 47 53 13 61
    // IntArray_add_rule(array, 75, 29); //  75 97 47 53 13 61 29
    // IntArray_add_rule(array, 61, 13); //  75 97 47 53    61 13 29  
    // IntArray_add_rule(array, 75, 53); //  75 97 47 53    61 13 29 
    // IntArray_add_rule(array, 29, 13); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 97, 29); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 53, 29); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 61, 53); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 97, 53); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 61, 29); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 47, 13); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 75, 47); //  75 97 47 53    61    29 13  
    // IntArray_add_rule(array, 97, 75); //     97 75 47 53    61 29 13  
    // IntArray_add_rule(array, 47, 61); //     97 75 47 61 53 61 29 13  
    // IntArray_add_rule(array, 75, 61); //     97 75 47 61 53 61 29 13  
    // IntArray_add_rule(array, 47, 29); //     97 75 47 61 53 61 29 13  
    // IntArray_add_rule(array, 75, 13); //     97 75 47 61 53 61 29 13  
    // IntArray_add_rule(array, 53, 13); //     97 75 47 61 53 61 29 13  

    // loop over update lines
    int valid_updates = 0;
    for (buf.i = updates_i; buf.i < buf.len; buffer_skip_to_next_line(&buf)) {
        char ch = buffer_peek(&buf);        
        int rule_i = 0;
        bool valid = true;
        bool at_least_one_number = false;
        int debug_line_start_i = buf.i;
        // loop over each number in an update
        while (is_digit(ch)) {
            int n = buffer_read_number(&buf, &ok);
            if (!ok) {
                break;
            } else {
                at_least_one_number = true;
            };
            bool match = false;
            
            while (rule_i < array.len) {
                if (IntArray_get(array, rule_i) == n) {
                    rule_i += 1;
                    match = true;
                    break;
                }
                rule_i += 1;
            }

            if (!match) {
                valid = false;
                break;
            }
            
            ch = buffer_peek(&buf);        
            if (ch == ',') {
                buf.i += 1;
                ch = buffer_peek(&buf);        
            }
        }

        // TODO: rewind and get middle number

        char * update_line = &buf.data[debug_line_start_i];
        if (valid && at_least_one_number) {
            valid_updates += 1;
        }
    }

    printf("%d\n", valid_updates);

    /*
    47|53           47 53
    97|13        97 47 53 13
    97|61        97 47 53 13 61
    97|47        97 47 53 13 61
    75|29     75 97 47 53 13 61 29
    61|13     75 97 47 53    61 13 29  
    75|53     75 97 47 53    61 13 29 
    29|13     75 97 47 53    61    29 13  
    97|29     75 97 47 53    61    29 13  
    53|29     75 97 47 53    61    29 13  
    61|53     75 97 47 53    61    29 13  
    97|53     75 97 47 53    61    29 13  
    61|29     75 97 47 53    61    29 13  
    47|13     75 97 47 53    61    29 13  
    75|47     75 97 47 53    61    29 13  
    97|75        97 75 47 53    61 29 13  
    47|61        97 75 47 61 53 61 29 13  
    75|61        97 75 47 61 53 61 29 13  
    47|29        97 75 47 61 53 61 29 13  
    75|13        97 75 47 61 53 61 29 13  
    53|13        97 75 47 61 53 61 29 13  
    */
    
    return 0;
}
