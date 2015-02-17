#include "coverage_stub.hpp"

int useful_function(int a, int b, int c, int d)
{
    if (a == b && c == d) {
        return 10;
    }
    if (a == 0) {
        return 1;
    }
    return 7;
}


int useless_function(int x, int y)
{
    return x + y;
}
