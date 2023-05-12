#!/usr/bin/awk -f
BEGIN {
    c = 0;
    pattern = ARGV[1];
    delete ARGV[1];
    count = ARGV[2];
    delete ARGV[2];
}
{
    if ($0 ~ pattern) {
        c++;
        next;
    }

    if (c >= count) {
        print;
    }
}
