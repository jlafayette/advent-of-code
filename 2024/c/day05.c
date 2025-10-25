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

void IntArray_clear(IntArray array) {
    for (int i = 0; i < array.len; i += 1) {
        array.items[i] = 0;
    }
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

        // scoot v2 1 along (didn't fix the issue)
        // int tmp = IntArray_get(array, v2_index+1);
        // IntArray_set(array, v2_index+1, v2);
        // IntArray_set(array, v2_index, tmp);
        
        changes_made = true;
    }
    return changes_made;
}

char * check_previous_rules(Buffer * buf, IntArray array) {
    char * result = NULL;
    int original_i = buf->i;

    for (buf->i = 0; buf->i < original_i; buffer_skip_to_next_line(buf)) {
        int line_start_i = buf->i;
        bool ok = false;
        int v1 = buffer_read_number(buf, &ok); if (!ok) { break; };
        buf->i += 1;  // discard '|'
        int v2 = buffer_read_number(buf, &ok); if (!ok) { break; };
        assert(v1 != v2);
        bool v1_found = false;
        bool v2_found = false;
        for (int i = 0; i < array.len; i += 1) {
            int v = IntArray_get(array, i);
            if (v == v1) {
                v1_found = true;
            }
            if (v == v2) {
                v2_found = true;
            }
            if (v2_found && !v1_found) {
                result = &buf->data[line_start_i];
                goto end;
            }
        }
    }
        
    end:
    buf->i = original_i;
    
    return result;
}

// Ordered Array -- holds the final ordered page rules

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
    return array;
}

bool IntDynamicArray_append(IntDynamicArray * array, int item) {
    if (array->len < array->cap) {
        array->items[array->len] = item;
        array->len += 1;
        return true;
    }
    return false;
}

bool IntDynamicArray_contains(IntDynamicArray array, int value) {
    for (int i = 0; i < array.len; i += 1) {
        if (value == array.items[i]) {
            return true;
        }
    }
    return false;
}

void IntDynamicArray_clear(IntDynamicArray * array) {
    array->len = 0;
}

typedef struct {
    int v1;
    int v2;
} Rule;

typedef struct {
    Rule * items;
    int len;
    int cap;
} RuleArray;


RuleArray RuleArray_new(int cap) {
    RuleArray array;
    array.len = 0;
    array.cap = 0;
    array.items = calloc(cap, sizeof(Rule));
    if (array.items) {
        array.cap = cap;
    }
    return array;
}

bool RuleArray_append(RuleArray * array, Rule item) {
    assert(array->len < array->cap);
    if (array->len < array->cap) {
        array->items[array->len] = item;
        array->len += 1;
        return true;
    }
    return false;
}

void RuleArray_clear(RuleArray * array) {
    array->len = 0;
}

// Tracker and TrackerDynamicArray

typedef struct {
    int value;
    int lf_count;
    int rt_count;
} Tracker;

typedef struct {
    Tracker * items;
    int len;
    int cap;
} TrackerDynamicArray;

TrackerDynamicArray TrackerDynamicArray_new(int cap) {
    TrackerDynamicArray array;
    array.len = 0;
    array.cap = 0;
    array.items = calloc(cap, sizeof(Tracker));
    if (array.items) {
        array.cap = cap;
    }
    return array;
}

bool TrackerDynamicArray_append(TrackerDynamicArray * array, Tracker item) {
    if (array->len < array->cap) {
        array->items[array->len] = item;
        array->len += 1;
        return true;
    }
    return false;
}

void TrackerDynamicArray_clear(TrackerDynamicArray * array) {
    array->len = 0;
}

void TrackerDynamicArray_add_rule(TrackerDynamicArray * array, int v1, int v2) {
    bool v1_found = false;
    bool v2_found = false;
    for (int i = 0; i < array->len; i += 1) {
        Tracker * t = &array->items[i];
        if (t->value == v1) {
            t->lf_count += 1;
            v1_found = true;
            continue;
        }
        if (t->value == v2) {
            t->rt_count += 1;
            v2_found = true;
        }
        if (v1_found && v2_found) {
            break;
        }
    }
    if (!v1_found) {
        Tracker t = {.value = v1, .lf_count = 1, .rt_count = 0};
        bool ok = TrackerDynamicArray_append(array, t);
        assert(ok);
    }
    if (!v2_found) {
        Tracker t = {.value = v2, .lf_count = 0, .rt_count = 1};
        bool ok = TrackerDynamicArray_append(array, t);
        assert(ok);
    }
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
    // int count = 0;
    // for (buf.i = updates_i; buf.i < buf.len; buf.i += 1) {
    //     bool ok = false;
    //     int n = buffer_read_number(&buf, &ok);
    //     if (ok) {
    //         count += 1;
    //     }
    // }
    
    // count all rules
    int rule_count = 0;
    for (buf.i = 0; buf.i < updates_i; buffer_skip_to_next_line(&buf)) {
        bool ok = false;
        int v1 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        buf.i += 1;  // discard '|'
        int v2 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        rule_count += 1;
    }
    RuleArray rules = RuleArray_new(rule_count);
    for (buf.i = 0; buf.i < updates_i; buffer_skip_to_next_line(&buf)) {
        bool ok = false;
        int v1 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        buf.i += 1;  // discard '|'
        int v2 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        Rule rule = {.v1=v1, .v2=v2};
        RuleArray_append(&rules, rule);
    }
    
    int update_count = 0;
    int longest_update = 0;
    buf.i = updates_i;
    // read all updates to get update stats
    while (buf.i < buf.len) {
        int current_update_len = 0;
        bool ok = true;
        // read single update loop
        while(ok) {
            int n = buffer_read_number(&buf, &ok);
            if (!ok) { break; }
            current_update_len += 1;
            if (buffer_peek(&buf) == ',') {
                buf.i += 1;
            }
        }
        buffer_skip_to_next_line(&buf);
        if (current_update_len > longest_update) {
            longest_update = current_update_len;
        }
        if (current_update_len > 0) {
            update_count += 1;
        }
    }

    // store the current update being evaluated
    IntDynamicArray update = IntDynamicArray_new(longest_update);
    // ordered rules (per update)
    IntDynamicArray ordered = IntDynamicArray_new(rules.len);
    // Track position of pages in the rules to find
    // one at the start or end
    TrackerDynamicArray tda = TrackerDynamicArray_new(rules.len);

    // loop over all updates
    int part1_result = 0;
    int valid_updates = 0;
    buf.i = updates_i;
    while (buf.i < buf.len) {

        // read single update to be evaluated
        IntDynamicArray_clear(&update);
        while (true) {
            bool ok = false;
            int n = buffer_read_number(&buf, &ok);
            if (!ok) { break; }
            IntDynamicArray_append(&update, n);
            if (buffer_peek(&buf) == ',') {
                buf.i += 1;
            }
        }
        buffer_skip_to_next_line(&buf);
        if (update.len == 0) {
            break;
        }

        
        // (evaluate 1) build ordered rules for current update
        TrackerDynamicArray_clear(&tda);
        IntDynamicArray_clear(&ordered);
        for (int i = 0; i < rules.len; i += 1) {
            Rule rule = rules.items[i];
            bool contains_v1 = IntDynamicArray_contains(update, rule.v1);
            bool contains_v2 = IntDynamicArray_contains(update, rule.v2);
            if (contains_v1 && contains_v2) {
                TrackerDynamicArray_add_rule(&tda, rule.v1, rule.v2);
            }
        }
        int total_page_numbers = tda.len;
        int last_page = 0;
        for (int i = 0; i < tda.len; i += 1) {
            Tracker t = tda.items[i];
            if (t.rt_count == 0) {
                bool ok = IntDynamicArray_append(&ordered, t.value);
                assert(ok);
            }
            if (t.lf_count == 0) {
                last_page = t.value;
            }
        }
        assert(ordered.len == 1);
        assert(last_page != 0);
        while (ordered.len < total_page_numbers) {
            TrackerDynamicArray_clear(&tda);
            for (int i = 0; i < rules.len; i += 1) {
                Rule rule = rules.items[i];
                bool contains_v1 = IntDynamicArray_contains(update, rule.v1);
                bool contains_v2 = IntDynamicArray_contains(update, rule.v2);
                if (contains_v1 && contains_v2 && !IntDynamicArray_contains(ordered, rule.v1)) {
                    TrackerDynamicArray_add_rule(&tda, rule.v1, rule.v2);
                }
            }
            if (tda.len == 0) {
                bool ok = IntDynamicArray_append(&ordered, last_page);
                assert(ok);
            }
            for (int i = 0; i < tda.len; i += 1) {
                Tracker t = tda.items[i];
                if (t.rt_count == 0) {
                    bool ok = IntDynamicArray_append(&ordered, t.value);
                    assert(ok);
                    break;
                }
            }
        }
        // (evaluate 2) check if current update is valid
        bool valid = true;
        int rule_i = 0;
        for (int i = 0; i < update.len; i += 1) {
            int n = update.items[i];
            bool match = false;
            while (rule_i < ordered.len) {
                if (ordered.items[rule_i] == n) {
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
        }
        if (valid) {
            valid_updates += 1;
            
            // if valid get middle number
            int middle_i = update.len / 2;
            int middle_number = update.items[middle_i];

            // add middle number to total
            part1_result += middle_number;
        }
    }

    // attempt 2
    /*
    // find number that is always on the right
    // find number that is always on the left
    TrackerDynamicArray tda = TrackerDynamicArray_new(64);
    IntDynamicArray ordered = IntDynamicArray_new(64);
    for (buf.i = 0; buf.i < updates_i; buffer_skip_to_next_line(&buf)) {
        bool ok = false;
        int v1 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        buf.i += 1;  // discard '|'
        int v2 = buffer_read_number(&buf, &ok); if (!ok) { break; };
        TrackerDynamicArray_add_rule(&tda, v1, v2);
    }
    int total_page_numbers = tda.len;
    int last_page = 0;
    for (int i = 0; i < tda.len; i += 1) {
        Tracker t = tda.items[i];
        if (t.rt_count == 0) {
            bool ok = IntDynamicArray_append(&ordered, t.value);
            assert(ok);
        }
        if (t.lf_count == 0) {
            last_page = t.value;
        }
    }
    assert(ordered.len == 1);
    assert(last_page != 0);
    while (ordered.len < total_page_numbers) {
        TrackerDynamicArray_clear(&tda);
        for (buf.i = 0; buf.i < updates_i; buffer_skip_to_next_line(&buf)) {
            bool ok = false;
            int v1 = buffer_read_number(&buf, &ok); if (!ok) { break; };
            buf.i += 1;  // discard '|'
            int v2 = buffer_read_number(&buf, &ok); if (!ok) { break; };
            if (!IntDynamicArray_contains(ordered, v1)) {
                TrackerDynamicArray_add_rule(&tda, v1, v2);
            }
        }
        if (tda.len == 0) {
            bool ok = IntDynamicArray_append(&ordered, last_page);
            assert(ok);
        }
        for (int i = 0; i < tda.len; i += 1) {
            Tracker t = tda.items[i];
            if (t.rt_count == 0) {
                bool ok = IntDynamicArray_append(&ordered, t.value);
                assert(ok);
                break;
            }
        }
    }
    */

    /*
    // attempt 1 -- didn't work on full input
    int changes = 1;
    int loop_count = 0;
    while (changes > 0 && loop_count < 1) {
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
            // check previous rules
            
            char * contradicted_rule = check_previous_rules(&buf, array);
            if (contradicted_rule != NULL) {
                break;
            }
        }
    }
    */
    
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
    
    // loop over update lines
    /*
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
            
            while (rule_i < ordered.len) {
                if (ordered.items[rule_i] == n) {
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
    */

    printf("%d   %d\n", valid_updates, part1_result);

    
    return 0;
}
