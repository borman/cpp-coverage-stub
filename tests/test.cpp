#include <cstdlib>
#include <cstdio>

#include "coverage_stub.hpp"

#define VERIFY(x) if (!(x)) { printf("Failed: %s\n", #x); abort(); }

int main() {
    VERIFY(useful_function(1, 1, 2, 2) == 10);
    VERIFY(useful_function(1, 2, 2, 2) == 7);
    return 0;
}
