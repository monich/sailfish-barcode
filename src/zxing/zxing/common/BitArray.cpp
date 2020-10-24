// -*- mode:c++; tab-width:2; indent-tabs-mode:nil; c-basic-offset:2 -*-
/*
 *  Copyright 2010 ZXing authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <zxing/common/BitArray.h>
#include <zxing/common/Array.h>
#include <cstring>
#include <sstream>

using std::vector;
using zxing::BitArray;

// VC++
using zxing::Ref;

namespace zxing {

int BitArray::makeArraySize(int size) {
    return (size + 31) / 32;
}

ArrayRef<int> BitArray::makeArray(int size) {
    return ArrayRef<int>((size + 31) / 32);
}

BitArray::BitArray(): size(0), bits(1) {}

BitArray::BitArray(int size_)
    : size(size_), bits(makeArraySize(size)) {}

BitArray::~BitArray() {
}

void BitArray::clear() {
    memset(&bits[0], 0, bits->size() * sizeof(int));
}

bool BitArray::isRange(int start, int end, bool value) {
    if (end < start) {
        throw IllegalArgumentException();
    }
    if (end == start) {
        return true; // empty range matches
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start / 32;
    int lastInt = end / 32;
    for (int i = firstInt; i <= lastInt; i++) {
        const int firstBit = (i > firstInt) ? 0 : (start & bitsMask);
        const int lastBit = (i < lastInt) ? 31 : (end & bitsMask);
        const int mask = (2 << lastBit) - (1 << firstBit);

        // Return false if we're looking for 1s and the masked bits[i] isn't all 1s (that is,
        // equals the mask, or we're looking for 0s and the masked portion is not all 0s
        if ((bits[i] & mask) != (value ? mask : 0)) {
            return false;
        }
    }
    return true;
}

void BitArray::reverse()
{
    ArrayRef<int> newBits(bits->size());
    // reverse all int's first
    int len = ((this->size-1) / 32);
    int oldBitsLen = len + 1;
    for (int i = 0; i < oldBitsLen; i++) {
      long x = (long) bits[i];
      x = ((x >>  1) & 0x55555555L) | ((x & 0x55555555L) <<  1);
      x = ((x >>  2) & 0x33333333L) | ((x & 0x33333333L) <<  2);
      x = ((x >>  4) & 0x0f0f0f0fL) | ((x & 0x0f0f0f0fL) <<  4);
      x = ((x >>  8) & 0x00ff00ffL) | ((x & 0x00ff00ffL) <<  8);
      x = ((x >> 16) & 0x0000ffffL) | ((x & 0x0000ffffL) << 16);
      newBits[len - i] = (int) x;
    }
    // now correct the int's if the bit size isn't a multiple of 32
    if (size != oldBitsLen * 32) {
      int leftOffset = oldBitsLen * 32 - size;
      int mask = 1;
      for (int i = 0; i < 31 - leftOffset; i++) {
        mask = (mask << 1) | 1;
      }
      int currentInt = (newBits[0] >> leftOffset) & mask;
      for (int i = 1; i < oldBitsLen; i++) {
        int nextInt = newBits[i];
        currentInt |= nextInt << (32 - leftOffset);
        newBits[i - 1] = currentInt;
        currentInt = (nextInt >> leftOffset) & mask;
      }
      newBits[oldBitsLen - 1] = currentInt;
    }
    bits = newBits;
}

BitArray::Reverse::Reverse(Ref<BitArray> array_) : array(array_) {
    array->reverse();
}

BitArray::Reverse::~Reverse() {
    array->reverse();
}

namespace {
// N.B.: This only works for 32 bit ints ...
int numberOfTrailingZeros(int i) {
    // HD, Figure 5-14
#if defined(__clang__) || defined(__GNUC__)
    return __builtin_ctz(i);
#else
    int y;
    if (i == 0) return 32;
    int n = 31;
    y = i <<16; if (y != 0) { n = n -16; i = y; }
    y = i << 8; if (y != 0) { n = n - 8; i = y; }
    y = i << 4; if (y != 0) { n = n - 4; i = y; }
    y = i << 2; if (y != 0) { n = n - 2; i = y; }
    return n - (((unsigned int)(i << 1)) >> 31);
#endif
}
}

int BitArray::getNextSet(int from) {
    if (from >= size) {
        return size;
    }
    int bitsOffset = from >> logBits;
    int currentBits = bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= ~((1 << (from & bitsMask)) - 1);
    while (currentBits == 0) {
        if (++bitsOffset == (int)bits->size()) {
            return size;
        }
        currentBits = bits[bitsOffset];
    }
    int result = (bitsOffset << logBits) + numberOfTrailingZeros(currentBits);
    return result > size ? size : result;
}

int BitArray::getNextUnset(int from) {
    if (from >= size) {
        return size;
    }
    int bitsOffset = from >> logBits;
    int currentBits = ~bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= ~((1 << (from & bitsMask)) - 1);
    while (currentBits == 0) {
        if (++bitsOffset == (int)bits->size()) {
            return size;
        }
        currentBits = ~bits[bitsOffset];
    }
    int result = (bitsOffset << logBits) + numberOfTrailingZeros(currentBits);
    return result > size ? size : result;
}

}
