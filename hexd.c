#include <errno.h>
#include <stdio.h>
#include <string.h>

// Do not run with spaces > 48
void printspaces(int spaces) {
    static char space[49] = "                                                ";

    space[spaces] = '\0';
    fputs(space, stdout);
    space[spaces] = ' ';
}

int main(int argc, char const* argv[]) {
    if (argc > 2) {
        fprintf(stderr, "Usage: %s [file]\n\tReads from STDIN if no argument is given.\n", argv[0]);
        return 1;
    }

    char* ends[8] = {" ", " ", " ", " ", " ", " ", " ", "  "};

    // Use stdin instead of opening a fule if there's no second argument
    FILE* file = argc == 2 ? fopen(argv[1], "rb") : stdin;

    // Exit if we can't open the file
    if (file == NULL) {
        fprintf(stderr, "Could not open file: %s\n", strerror(errno));
        return 1;
    }

    // Unsigned so that bytes over 0x7f don't show up weirdly
    unsigned char bytes[16];
    int index = 0, read;

    for (;; index += read) {
        read = fread(bytes, sizeof(char), 16, file);
        // Only check for EOF when nothing has been read
        // so that we get the half-empty lines
        if (read <= 0) {
            if (feof(file)) break;
            fprintf(stderr, "Could not read file: %s\n", strerror(errno));
            fclose(file);
            return 1;
        }
        printf("%08x  ", index);
        for (int i = 0; i < read; i++) {
            printf("%02x%s", bytes[i], ends[i & 7]);
        }
        // Print all the missing space if this was a 
        if (read != 16) {
            int spaces = 1 + (16 - read) * 3 + (15 - read) / 8;
            printspaces(spaces);
        }
        putchar('|');
        for (int i = 0; i < read; i++) {
            char c = bytes[i];
            // Replace non-printable characters with periods
            if (c < 0x20 || c >= 0x7f)
                putchar('.');
            else
                putchar(c);
        }
        puts("|");
    }
    printf("%08x\n", index);

    fclose(file);

    return 0;
}
