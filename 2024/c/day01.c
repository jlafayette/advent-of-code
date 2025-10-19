#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>

#include "arrays.c"
#include "read_file.h"

// --- buffer

typedef struct {
  char * data;
  int len;
  int i;
} Buffer;

char buffer_peek(Buffer * buf) {
  
  if (buf->i >= buf->len) {
    return 0;
  }
  char ch =  buf->data[buf->i];
  return ch;
}

bool is_digit(char ch) {
  return ch >= '0' && ch <= '9';
}
bool is_newline(char ch) {
  return ch == '\n';
}
bool is_interesting(char ch) {
  return is_digit(ch) || is_newline(ch);
}

void buffer_skip(Buffer * buf) {
  if (buf->i >= buf->len) {
    return;
  }
  char next = buffer_peek(buf);
  while (!is_interesting(next) && buf->i < buf->len) {
    buf->i += 1;
    next = buffer_peek(buf);
  }
}

int i_pow(int base, int exponent) {
  return (int)pow((double)base, (double)exponent);
}

int digitCharArray_to_number(char * digitCharArray, int len) {
  int sum = 0;
  int exponent = 0;
  for (int i = len-1; i >= 0; i -= 1) {
    int n = (int)digitCharArray[i];
    sum += n * i_pow(10, exponent);
    exponent += 1;
  }
  return sum;
}

int buffer_read_number(Buffer * buf, bool * ok) {
  *ok = false;
  if (buf->i >= buf->len) {
    return 0;
  }
  char ch = buffer_peek(buf);
  if (!is_digit(ch)) {
    return 0;
  }
  
  char digitCharArray[10];
  for (int i = 0; i < 10; i += 1) {
    digitCharArray[i] = 0;
  }
  int di = 0;
    
  while (is_digit(ch)) {
    digitCharArray[di] = ch - '0';
    di += 1;
    buf->i += 1;
    if (buf->i >= buf->len) {
      break;
    }
    ch = buffer_peek(buf);
  }
  if (di > 0) {
    *ok = true;
  }
  int n = digitCharArray_to_number(digitCharArray, di);
  return n;
}
void buffer_skip_to_newline(Buffer * buf) {
  if (buf->i >= buf->len) {
    return;
  }
  char ch = buffer_peek(buf);
  while (!is_newline(ch) && buf->i <= buf->len) {
    buf->i += 1;
    ch = buffer_peek(buf);
  }
  buf->i += 1;
}

void Int32Array_set_sorted(Int32Array array, int32_t value) {
    // start at right side
    // if inserting into an already "full" array, push values off the left side
    // (discard smallest)
    int i = 0;
    for (i = array.len-1; i >= 0; i -= 1) {
        int32_t current = array.items[i];
        if (value > current) {
            break;
        }
    }
    if (i < 0) {
        return;
    }
    if (i == 0) {
        Int32Array_set(array, i, value);
        return;
    }
    memmove(array.items, array.items+1, i*sizeof(int32_t));
    Int32Array_set(array, i, value);
}

int32_t diff(int32_t a, int32_t b) {
  if (a > b) {
    return (a - b);
  } else {
    return (b - a);
  }
}
 
// --- main

int main(int argc, char *argv[]) {
  char * filename = "input_test1.txt";
  if (argc == 2) {
    filename = argv[1];
  }
  FileReadResult file_result = read_entire_file(filename);
  if (!file_result.ok) {
    return 1;
  }
  int i = 0;
  int line_count = 0; 
  while (1) {
    if (i >= file_result.length) {
      break;
    }
    char ch = file_result.buffer[i];
    if (ch == '\n') {
      line_count += 1;
    }
    i++;
  }
  
  Int32Array lf_array = Int32Array_new(line_count);
  Int32Array rt_array = Int32Array_new(line_count);
  Buffer buf = {
    .data = file_result.buffer,
    .len = file_result.length,
    .i = 0
  };
  while (buf.i < buf.len) {
    buffer_skip(&buf);
    bool lf_ok = false;
    int lf_number = buffer_read_number(&buf, &lf_ok);
    buffer_skip(&buf);
    bool rt_ok = false;
    int rt_number = buffer_read_number(&buf, &rt_ok);
    buffer_skip_to_newline(&buf);
    if (lf_ok && rt_ok) {
      Int32Array_set_sorted(lf_array, lf_number);
      Int32Array_set_sorted(rt_array, rt_number);
    }
  }

  // part 1
  // first smallest lf and pair with smallest rt
  // should sort both lists and then compare one at a time
  int32_t part1_result = 0;
  for (int i = 0; i < lf_array.len; i += 1) {
    part1_result += diff(Int32Array_get(lf_array, i), Int32Array_get(rt_array, i));
  }
  printf("%d\n", part1_result);

  // part 2
  int part2_result = 0;
  int rt_i = 0;
  for (int lf_i = 0; lf_i < lf_array.len; lf_i += 1) {
    int32_t lf_v = Int32Array_get(lf_array, lf_i);
    int rt_off = 0;
    while (rt_i + rt_off < rt_array.len) {
      int32_t rt_v = Int32Array_get(rt_array, rt_i + rt_off);
      if (rt_v < lf_v) {
        rt_i += 1;
        continue;
      }
      if (rt_v == lf_v) {
        rt_off += 1;
        continue;
      } else {
        break;
      }
    }
    part2_result += lf_v * rt_off;
  }
  printf("%d\n", part2_result);
  
  return 0;
}

