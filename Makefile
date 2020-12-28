TITLE = car-simulator

COMMON_FLAGS = -Wall -Wextra -Wpedantic -Werror -std=c99\

CFLAGS_DEBUG = $(COMMON_FLAGS) -fsanitize=undefined,address,leak -g

CFLAGS_RELEASE = $(COMMON_FLAGS) -O2

all:
	gcc $(CFLAGS_RELEASE) main.c -o $(TITLE)

debug:
	gcc $(CFLAGS_DEBUG) main.c -o $(TITLE)

clean:
	rm $(TITLE) *.o

run:
	./$(TITLE)

production:
	clang $(CFLAGS_RELEASE) main.c -o $(TITLE)

asm:
	fasm main.asm $(TITLE)
