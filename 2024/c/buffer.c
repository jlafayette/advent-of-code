#include <math.h>
#include <stdbool.h>
#include <inttypes.h>

typedef struct {
  char * data;
  int len;
  int i;
} Buffer;

char buffer_peek(Buffer buf) {
  if (buf.i >= buf.len) {
    return 0;
  }
  char ch =  buf.data[buf.i];
  return ch;
}
char buffer_peek_i(Buffer buf, int off) {
  int i = buf.i + off;
  if (i >= buf.len || i < 0) {
    return 0;
  }
  char ch = buf.data[i];
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
  char next = buffer_peek(*buf);
  while (!is_interesting(next) && buf->i < buf->len) {
    buf->i += 1;
    next = buffer_peek(*buf);
  }
}

int buffer_read_number(Buffer * buf, bool * ok) {
  *ok = false;
  if (buf->i >= buf->len) {
    return 0;
  }
  char ch = buffer_peek(*buf);
  if (!is_digit(ch)) {
    return 0;
  }
  
  int n = 0;
  while (is_digit(ch)) {
    char ch_n = ch - '0';
    n = (n * 10) + (int)ch_n;
    buf->i += 1;
    if (buf->i >= buf->len) {
      break;
    }
    ch = buffer_peek(*buf);
  }
  *ok = true;
  return n;
}

uint64_t buffer_read_u64(Buffer * buf, bool * ok) {
  *ok = false;
  if (buf->i >= buf->len) {
    return 0;
  }
  char ch = buffer_peek(*buf);
  if (!is_digit(ch)) {
    return 0;
  }
  
  uint64_t n = 0;
  while (is_digit(ch)) {
    char ch_n = ch - '0';
    n = (n * 10) + (uint64_t)ch_n;
    buf->i += 1;
    if (buf->i >= buf->len) {
      break;
    }
    ch = buffer_peek(*buf);
  }
  *ok = true;
  return n;
}

int buffer_read_next_number(Buffer * buf, bool * ok) {
    buffer_skip(buf);
    return buffer_read_number(buf, ok);
}

void buffer_skip_to_next_line(Buffer * buf) {
  if (buf->i >= buf->len) {
    return;
  }
  char ch = buffer_peek(*buf);
  while (!is_newline(ch) && buf->i <= buf->len) {
    buf->i += 1;
    ch = buffer_peek(*buf);
  }
  buf->i += 1;
}

int buffer_line_count(Buffer buf) {
  int count = 1;
  for (buf.i = 0; buf.i < buf.len; buf.i += 1) {
    char ch = buffer_peek(buf);
    if (ch == '\n') {
      count += 1;
    }
  }
  return count;
}

