#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdbool.h>

typedef struct {
  char * buffer;
  long length;
  bool ok;
} FileReadResult;

void FileReadResult_free(FileReadResult r) {
  if (r.ok) {
    free(r.buffer);
  }
}

FileReadResult read_entire_file(char * filename) {
  FileReadResult r;
  r.buffer = 0;
  r.length = 0;
  r.ok = false;

  FILE * f = fopen(filename, "rb");
  if (!f) {
    goto cleanup_and_return;
  }
  int fseek_ok = fseek(f, 0, SEEK_END);
  if (fseek_ok != 0) {
    goto cleanup_and_return;
  }
  r.length = ftell(f);
  if (r.length == -1) {
    goto cleanup_and_return;
  }
  fseek_ok = fseek(f, 0, SEEK_SET);
  if (fseek_ok != 0) {
    goto cleanup_and_return;
  }
  // printf("length=%d\n", r.length);
  r.buffer = malloc(r.length + 1);
  r.buffer[r.length] = '\0';
  if (!r.buffer) {
    goto cleanup_and_return;
  }
  size_t bytes_read = fread(r.buffer, 1, r.length, f);
  if (bytes_read < r.length) {
    fprintf(stderr, "bytes_read(%d) < length(%d)\n", bytes_read, r.length);
    goto cleanup_and_return;
  }
  r.buffer[r.length] = '\0';
  r.length += 1;
  r.ok = true;

  cleanup_and_return:
  
  if (!r.ok) {
    perror("Error reading file");
    if (r.buffer) {
      free(r.buffer);
    }
  }
  if (f) {
    fclose(f);
  }
  return r;
}

