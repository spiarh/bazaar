#!/usr/bin/env python3

import math
import random
import string
import sys

DEFAULT_SIZE = 36
DEFAULT_DIVIDE = 9
SPECIAL_CHARS = "-_#@="


def pwgen(size):
    chars = string.ascii_letters + string.digits
    max_random_special = math.ceil(size/DEFAULT_DIVIDE)
    num_random_special = (random.randint(0, (size-1)) for _ in range(0, max_random_special))
    rand_chars = list(random.SystemRandom().choice(chars) for _ in range(size))

    for i in num_random_special:
        rand_chars[i] = random.SystemRandom().choice(SPECIAL_CHARS)

    return ''.join(rand_chars)


def main(argv):
    size = DEFAULT_SIZE
    if len(argv) >= 1:
        size = int(argv[0])
    print(pwgen(size))


if __name__ == "__main__":
    main(sys.argv[1:])
