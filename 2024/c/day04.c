#include <stdio.h>
#include <stdbool.h>

#include "read_file.c"
#include "buffer.c"

bool xmas_forward(Buffer buf) {
    return buffer_peek_i(&buf, 0) == 'X'
        && buffer_peek_i(&buf, 1) == 'M'
        && buffer_peek_i(&buf, 2) == 'A'
        && buffer_peek_i(&buf, 3) == 'S';
}
bool xmas_backward(Buffer buf) {
    return buffer_peek_i(&buf,  0) == 'X'
        && buffer_peek_i(&buf, -1) == 'M'
        && buffer_peek_i(&buf, -2) == 'A'
        && buffer_peek_i(&buf, -3) == 'S';
}
bool xmas_down(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                ) == 'X'
        && buffer_peek_i(&buf, (width*1)+(gap*1)) == 'M'
        && buffer_peek_i(&buf, (width*2)+(gap*2)) == 'A'
        && buffer_peek_i(&buf, (width*3)+(gap*3)) == 'S';
}
bool xmas_up(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                  ) == 'X'
        && buffer_peek_i(&buf, (width*-1)+(gap*-1)) == 'M'
        && buffer_peek_i(&buf, (width*-2)+(gap*-2)) == 'A'
        && buffer_peek_i(&buf, (width*-3)+(gap*-3)) == 'S';
}
bool xmas_diagonal_forward_down(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                  ) == 'X'
        && buffer_peek_i(&buf, (width*1)+(gap*1)+1) == 'M'
        && buffer_peek_i(&buf, (width*2)+(gap*2)+2) == 'A'
        && buffer_peek_i(&buf, (width*3)+(gap*3)+3) == 'S';
}
bool xmas_diagonal_forward_up(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                    ) == 'X'
        && buffer_peek_i(&buf, (width*-1)+(gap*-1)+1) == 'M'
        && buffer_peek_i(&buf, (width*-2)+(gap*-2)+2) == 'A'
        && buffer_peek_i(&buf, (width*-3)+(gap*-3)+3) == 'S';
}
bool xmas_diagonal_backward_down(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                  ) == 'X'
        && buffer_peek_i(&buf, (width*1)+(gap*1)-1) == 'M'
        && buffer_peek_i(&buf, (width*2)+(gap*2)-2) == 'A'
        && buffer_peek_i(&buf, (width*3)+(gap*3)-3) == 'S';
}
bool xmas_diagonal_backward_up(Buffer buf, int width, int gap) {
    return buffer_peek_i(&buf, 0                    ) == 'X'
        && buffer_peek_i(&buf, (width*-1)+(gap*-1)-1) == 'M'
        && buffer_peek_i(&buf, (width*-2)+(gap*-2)-2) == 'A'
        && buffer_peek_i(&buf, (width*-3)+(gap*-3)-3) == 'S';
}
bool x_mas(Buffer buf, int width, int gap) {
    char A_x = buffer_peek_i(&buf,                   0);
    char _B_ = buffer_peek_i(&buf, (width*1)+(gap*1)+1);
    char x_C = buffer_peek_i(&buf,                   2);
    char x_D = buffer_peek_i(&buf, (width*2)+(gap*2)+2);
    char E_x = buffer_peek_i(&buf, (width*2)+(gap*2)+0);
    return _B_ == 'A'
      && ((A_x == 'M' && x_D == 'S') || (A_x == 'S' && x_D == 'M'))
      && ((E_x == 'M' && x_C == 'S') || (E_x == 'S' && x_C == 'M'))
    ;
}

int main(int argc, char * argv[]) {
    char * filename = "input_4_1_ex.txt";
    if (argc == 2) {
        filename = argv[1];
    }
    Buffer buf = { .i=0 };
    bool ok = false;
    buf.data = read_entire_file2(filename, &ok, &buf.len);
    if (!ok) {
        return 1;
    }

    int width = 0;
    int line_gap = 1; // if \r\n 2, if only \n 1
    for (buf.i=0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(&buf);
        if (ch == 'X' || ch == 'M' || ch == 'A' || ch == 'S') {
            width += 1;
        }
        if (ch == '\r') {
            line_gap = 2;
        }
        if (ch == '\n') {
            break;
        }
    }

    // part 1
    // find all occurances of XMAS
    
    int xmas = 0;
    for (buf.i=0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(&buf);
        if (ch == 'X') {
            if (xmas_forward               (buf                 )) { xmas += 1; }
            if (xmas_backward              (buf                 )) { xmas += 1; }
            if (xmas_up                    (buf, width, line_gap)) { xmas += 1; }
            if (xmas_down                  (buf, width, line_gap)) { xmas += 1; }
            if (xmas_diagonal_forward_down (buf, width, line_gap)) { xmas += 1; }
            if (xmas_diagonal_forward_up   (buf, width, line_gap)) { xmas += 1; }
            if (xmas_diagonal_backward_down(buf, width, line_gap)) { xmas += 1; }
            if (xmas_diagonal_backward_up  (buf, width, line_gap)) { xmas += 1; }
        }
    }

    printf("%d\n", xmas);

    // part 2
    // find all the X-MAS
    
    xmas = 0;
    for (buf.i=0; buf.i < buf.len; buf.i += 1) {
        char ch = buffer_peek(&buf);
        if (x_mas(buf, width, line_gap)) {
            xmas += 1;
            // printf("%c", ch);
        } else {
            // if (ch == '\n' || ch == '\r') {
            //     printf("%c", ch);
            // } else {
            //     printf(".");
            // }
        }
    }
    
    printf("%d\n", xmas);
    
    return 0;
}
