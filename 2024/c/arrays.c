#include <stdint.h>
#include <stdbool.h>

// --- Array

typedef struct {
    int32_t * items;
    int len;
} Int32Array;

Int32Array Int32Array_new(int len) {
    Int32Array array;
    array.items = calloc(len, sizeof(int32_t));
    if (array.items) {
        array.len = len;
    }
    return array;
}

int32_t Int32Array_get(Int32Array array, int index) {
    if (index >= 0 && index < array.len) {
        return array.items[index];
    }
    return 0;
}

int32_t * Int32Array_get_ptr(Int32Array array, int index) {
    if (index >= 0 && index < array.len) {
        return &array.items[index];
    }
    return NULL;
}

bool Int32Array_set(Int32Array array, int index, int32_t value) {
    if (index >= 0 && index < array.len) {
        array.items[index] = value;
        return true;
    }
    return false;
}

// --- Dynamic Array

typedef struct {
    int32_t * items;
    int len;
    int cap;
} Int32DynamicArray;

Int32DynamicArray Int32DynamicArray_new(int cap) {
    Int32DynamicArray array;
    array.items = calloc(cap, sizeof(int32_t));
    if (array.items) {
        array.cap = cap;
    }
    return array;
}

int32_t Int32DynamicArray_get(Int32DynamicArray array, int index) {
    if (index >= 0 && index < array.len) {
        return array.items[index];
    }
    return 0;
}

int32_t * Int32DynamicArray_get_ptr(Int32DynamicArray array, int index) {
    if (index >= 0 && index < array.len) {
        return &array.items[index];
    }
    return NULL;
}

bool Int32DynamicArray_append(Int32DynamicArray array, int item) {
    if (array.len < array.cap) {
        array.items[array.len] = item;
        array.len += 1;
        return true;
    }
    return false;
}

