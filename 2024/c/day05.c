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

    // find index where updates start
    for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
        if (buffer_after_two_new_lines(buf)) {
            break;
        }
    }
    int updates_i = buf.i;
    
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
    
    int longest_update = 0;
    buf.i = updates_i;
    // read all updates to get update stats
    while (buf.i < buf.len) {
        int current_length = 0;
        bool ok = true;
        // read single update loop
        while(ok) {
            int n = buffer_read_number(&buf, &ok);
            if (!ok) { break; }
            current_length += 1;
            if (buffer_peek(&buf) == ',') {
                buf.i += 1;
            }
        }
        buffer_skip_to_next_line(&buf);
        if (current_length > longest_update) {
            longest_update = current_length;
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
    int part2_result = 0;
    int valid_updates = 0;
    int invalid_updates = 0;
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
        } else {
            // if invalid, the corrected one will be the ordered
            // version of the pages for the selected rules
            invalid_updates += 1;
            
            int middle_i = ordered.len / 2;
            int middle_number = ordered.items[middle_i];
            
            part2_result += middle_number;
        }
    }

    printf("%d   %d\n", valid_updates, part1_result);
    
    printf("%d   %d\n", invalid_updates, part2_result);
    
    return 0;
}
