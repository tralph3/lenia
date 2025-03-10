package main

proper_mod :: proc (#any_int a, #any_int b: int) -> int {
    return (a % b + b) % b
}
