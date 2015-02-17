#include "coverage_stub.hpp"

int totally_useless_function(int x)
{
    if (x % 2 == 0) {
        return x + 3;
    } else {
        return x - 2;
    }
}
