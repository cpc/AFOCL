/* COMP.CE.350 Parallelization Exercise util functions
   Copyright (c) 2023 Topi Leppanen topi.leppanen@tuni.fi
*/

#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>
#include <stdlib.h>

#define PI (3.14159265358979323846)

void cannyEdgeDetection_ref(
    uint8_t* __restrict input, size_t width, size_t height,
    uint16_t threshold_lower, uint16_t threshold_upper,
    int gaussian_kernel_enabled,
    uint8_t* __restrict output);


void sobel3x3_ref(
    const uint8_t* __restrict in, size_t width, size_t height,
    int16_t* __restrict output_x, int16_t* __restrict output_y);

void gaussian3x3_ref(
    const uint8_t* __restrict in, size_t width, size_t height,
    uint8_t* __restrict output);

void phaseAndMagnitude_ref(
    const int16_t* __restrict in_x, const int16_t* __restrict in_y,
    size_t width, size_t height, uint8_t* __restrict phase_out,
    uint16_t* __restrict magnitude_out);

void nonMaxSuppression_ref(
    const uint16_t* __restrict magnitude, const uint8_t* __restrict phase,
    size_t width, size_t height, uint16_t threshold_lower,
    uint16_t threshold_upper, uint8_t* __restrict out);

uint8_t* read_pgm(char* path, size_t* output_width, size_t* output_height);

int write_pgm(char* path, uint8_t* image, size_t width, size_t height);

uint64_t gettimemono_ns();

int validate_result(
    uint8_t* output, uint8_t* golden, size_t width, size_t height,
    uint8_t* fused);

#endif
