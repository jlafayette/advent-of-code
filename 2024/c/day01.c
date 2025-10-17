#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>
#include <math.h>

#include "arrays.c"
#include "read_file.h"

// --- Line

typedef struct {
  int count;
  int lf;
  int rt;
} Line;

Line line_empty() {
    Line empty_line = {.count=0, .lf=0, .rt=0};
    return empty_line;
}

void line_add_number(Line * line, int n) {
  if (line->count == 0) {
    line->lf = n;
  } else if (line->count == 1) {
    line->rt = n;
  }
  line->count += 1;
}

// --- LineArray

typedef struct {
    Line * items;
    int len;
} LineArray;

LineArray LineArray_new(int len) {
    LineArray array;
    array.items = calloc(len, sizeof(Line));
    if (array.items) {
        array.len = len;
    }
    return array;
}

Line LineArray_get(LineArray array, int index) {
    if (index >= 0 && index < array.len) {
        return array.items[index];
    }
    return line_empty();
}

Line * LineArray_get_ptr(LineArray array, int index) {
    if (index >= 0 && index < array.len) {
        return &array.items[index];
    }
    return NULL;
}

bool LineArray_set(LineArray array, int index, Line value) {
    if (index >= 0 && index < array.len) {
        array.items[index] = value;
        return true;
    }
    return false;
}

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

bool read_line(Buffer * buf, Line * out_line) {
  Line line = line_empty();

  buffer_skip(buf);
  bool ok;
  int lf = buffer_read_number(buf, &ok);
  if (ok) {
    line_add_number(&line, lf);
  }
  buffer_skip(buf);
  int rt = buffer_read_number(buf, &ok);
  if (ok) {
    line_add_number(&line, rt);
  }
  buffer_skip_to_newline(buf);
  
  if (line.count == 2) {
    out_line->count = line.count;
    out_line->lf = line.lf;
    out_line->rt = line.rt;
    return true;
  } else {
    return false;
  }
}

// --- main

int main(int argc, char *argv[]) {
  char * filename = "input_test1.txt";
  if (argc == 2) {
    filename = argv[1];
  }
  FileReadResult r = read_entire_file(filename);
  if (!r.ok) {
    return 1;
  }
  int i = 0;
  int lines = 0; 
  while (1) {
    if (i >= r.length) {
      break;
    }
    char ch = r.buffer[i];
    if (ch == '\n') {
      lines += 1;
    }
    i++;
  }
  LineArray line_array = LineArray_new(lines);
  
  int line_array_i = 0;
  Buffer buf = {
    .data = r.buffer,
    .len = r.length,
    .i = 0
  };
  char * debug_line = &buf.data[buf.i]; // for seeing current line in debugger
  while (buf.i < buf.len) {
    Line out = line_empty();
    debug_line = &buf.data[buf.i];
    bool ok = read_line(&buf, &out); 
    if (ok) {
      LineArray_set(line_array, line_array_i, out);
      line_array_i += 1;
    }
  }
  return 0;
}
