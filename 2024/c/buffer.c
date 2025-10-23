#include <math.h>
#include <stdbool.h>

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
char buffer_peek_i(Buffer * buf, int off) {
  int i = buf->i + off;
  if (i >= buf->len) {
    return 0;
  }
  char ch = buf->data[i];
  return ch;
}
char buffer_peek_i2(Buffer buf, int off) {
  int i = buf.i + off;
  if (i >= buf.len) {
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

int buffer_read_next_number(Buffer * buf, bool * ok) {
    buffer_skip(buf);
    return buffer_read_number(buf, ok);
}

void buffer_skip_to_next_line(Buffer * buf) {
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

