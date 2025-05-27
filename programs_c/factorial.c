int mul(int a, int b);
int factorial(int value);

int main() {
    return factorial(5);
}

int mul(int a, int b) {
    int result = 0;
    while (b != 0) {
        if ((b & 0x1) == 0x1) result += a;
        b >>= 1;
        a <<= 1;
    }
    return result;
}

int factorial(int value) {
    if (value == 0) return 1;
    return mul(value, factorial(value - 1));
}
