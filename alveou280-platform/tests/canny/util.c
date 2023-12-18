/* COMP.CE.350 Parallelization Exercise util functions
   Copyright (c) 2023 Topi Leppanen topi.leppanen@tuni.fi
*/

#include "util.h"

#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

typedef struct {
    uint16_t x;
    uint16_t y;
} coord_t;

const coord_t neighbour_offsets_ref[8] = {
    {-1, -1}, {0, -1},  {+1, -1}, {-1, 0},
    {+1, 0},  {-1, +1}, {0, +1},  {+1, +1},
};

// Utility function to convert 2d index with offset to linear index
// Uses clamp-to-edge out-of-bounds handling
// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
size_t
idx_ref(size_t x, size_t y, size_t width, size_t height, int xoff, int yoff) {
    size_t resx = x;
    if ((xoff > 0 && x < width - xoff) || (xoff < 0 && x >= (-xoff)))
        resx += xoff;
    size_t resy = y;
    if ((yoff > 0 && y < height - yoff) || (yoff < 0 && y >= (-yoff)))
        resy += yoff;
    return resy * width + resx;
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
void
sobel3x3_ref(
    const uint8_t* __restrict in, size_t width, size_t height,
    int16_t* __restrict output_x, int16_t* __restrict output_y) {
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            /* 3x3 sobel filter, first in x direction */
            output_x[gid] = (-1) * in[idx_ref(x, y, width, height, -1, -1)] +
                            1 * in[idx_ref(x, y, width, height, 1, -1)] +
                            (-2) * in[idx_ref(x, y, width, height, -1, 0)] +
                            2 * in[idx_ref(x, y, width, height, 1, 0)] +
                            (-1) * in[idx_ref(x, y, width, height, -1, 1)] +
                            1 * in[idx_ref(x, y, width, height, 1, 1)];

            /* 3x3 sobel filter, in y direction */
            output_y[gid] = (-1) * in[idx_ref(x, y, width, height, -1, -1)] +
                            1 * in[idx_ref(x, y, width, height, -1, 1)] +
                            (-2) * in[idx_ref(x, y, width, height, 0, -1)] +
                            2 * in[idx_ref(x, y, width, height, 0, 1)] +
                            (-1) * in[idx_ref(x, y, width, height, 1, -1)] +
                            1 * in[idx_ref(x, y, width, height, 1, 1)];
        }
    }
}

void
gaussian3x3_ref(
    const uint8_t* __restrict in, size_t width, size_t height,
    uint8_t* __restrict output) {
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;
            uint16_t output_val =
                            1 * in[idx_ref(x, y, width, height, -1, -1)] +
                            2 * in[idx_ref(x, y, width, height,  0, -1)] +
                            1 * in[idx_ref(x, y, width, height,  1, -1)] +
                            2 * in[idx_ref(x, y, width, height, -1,  0)] +
                            4 * in[idx_ref(x, y, width, height,  0,  0)] +
                            2 * in[idx_ref(x, y, width, height,  1,  0)] +
                            1 * in[idx_ref(x, y, width, height, -1,  1)] +
                            2 * in[idx_ref(x, y, width, height,  0,  1)] +
                            1 * in[idx_ref(x, y, width, height,  1,  1)];

            output[gid] = (uint8_t)(output_val / 16);
        }
    }
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
void
phaseAndMagnitude_ref(
    const int16_t* __restrict in_x, const int16_t* __restrict in_y,
    size_t width, size_t height, uint8_t* __restrict phase_out,
    uint16_t* __restrict magnitude_out) {
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            // Output in range -PI:PI
            float angle = atan2(in_y[gid], in_x[gid]);

            // Shift range -1:1
            angle /= PI;

            // Shift range -127.5:127.5
            angle *= 127.5;

            // Shift range 0:255
            angle += (127.5 + 0.5);

            // Clamp to 0:255 before casting to a narrower type
            //phase_out[gid] = (uint8_t)fmin(255.0, fmax(angle, 0.0));
            phase_out[gid] = (uint8_t)(angle);

            magnitude_out[gid] = abs(in_x[gid]) + abs(in_y[gid]);
        }
    }
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
void
nonMaxSuppression_ref(
    const uint16_t* __restrict magnitude, const uint8_t* __restrict phase,
    size_t width, size_t height, uint16_t threshold_lower,
    uint16_t threshold_upper, uint8_t* __restrict out) {
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t gid = y * width + x;

            uint8_t sobel_angle = phase[gid];

            if (sobel_angle > 127) {
                sobel_angle -= 128;
            }

            int sobel_orientation = 0;

            if (sobel_angle < 16 || sobel_angle >= (7 * 16)) {
                sobel_orientation = 2;
            } else if (sobel_angle >= 16 && sobel_angle < 16 * 3) {
                sobel_orientation = 1;
            } else if (sobel_angle >= 16 * 3 && sobel_angle < 16 * 5) {
                sobel_orientation = 0;
            } else if (sobel_angle > 16 * 5 && sobel_angle <= 16 * 7) {
                sobel_orientation = 3;
            }

            uint16_t sobel_magnitude = magnitude[gid];
            /*
                        printf (
                                "x=%lu, y=%lu, sobel_magnitude=%u,
               sobel_angle=%u, orientation1=%u\n", x, y, sobel_magnitude,
               sobel_angle, sobel_orientation);
            */
            /* Non-maximum suppression
             * Pick out the two neighbours that are perpendicular to the
             * current edge pixel */
            uint16_t neighbour_max = 0;
            uint16_t neighbour_max2 = 0;
            switch (sobel_orientation) {
                case 0:
                    neighbour_max =
                        magnitude[idx_ref(x, y, width, height, 0, -1)];
                    neighbour_max2 =
                        magnitude[idx_ref(x, y, width, height, 0, 1)];
                    break;
                case 1:
                    neighbour_max =
                        magnitude[idx_ref(x, y, width, height, -1, -1)];
                    neighbour_max2 =
                        magnitude[idx_ref(x, y, width, height, 1, 1)];
                    break;
                case 2:
                    neighbour_max =
                        magnitude[idx_ref(x, y, width, height, -1, 0)];
                    neighbour_max2 =
                        magnitude[idx_ref(x, y, width, height, 1, 0)];
                    break;
                case 3:
                default:
                    neighbour_max =
                        magnitude[idx_ref(x, y, width, height, 1, -1)];
                    neighbour_max2 =
                        magnitude[idx_ref(x, y, width, height, -1, 1)];
                    break;
            }

            if ((sobel_magnitude < neighbour_max) ||
                (sobel_magnitude < neighbour_max2)) {
                /*     printf ("SUPPRESSING x=%lu, y=%lu, neighbour_max=%d,
                   sobel_magnitude=%d " "neightbor_tmp=%d\n", x, y,
                   neighbour_max, sobel_magnitude, neighbour_max2);
                     */
                sobel_magnitude = 0;
            } else {
                if (sobel_magnitude > threshold_lower) {
                  /*  printf ("KEEPING x=%lu, y=%lu, neighbour_max=%d, sobel_magnitude=%d "
                            "neightbor_tmp=%d\n",
                            x, y, neighbour_max, sobel_magnitude, neighbour_max2);
               */ }
            }

            /* Double thresholding */
            // Marks YES pixels with 255, NO pixels with 0 and MAYBE pixels
            // with 127
            uint8_t t = 127;
            if (sobel_magnitude > threshold_upper) t = 255;
            if (sobel_magnitude <= threshold_lower) t = 0;
            out[gid] = t;
        }
    }
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
void
edgeTracing_ref(uint8_t* __restrict image, size_t width, size_t height) {
    // Uses a stack-based approach to incrementally spread the YES
    // pixels to every (8) neighbouring MAYBE pixel.
    //
    // Modifies the pixels in-place.
    //
    // Since the same pixel is never added to the stack twice,
    // the maximum stack size is quaranteed to never be above
    // the image size and stack overflow should be impossible
    // as long as stack size is 2*2*image_size (2 16-bit coordinates per
    // pixel).
    coord_t* tracing_stack = malloc(width * height * sizeof(coord_t));
    coord_t* tracing_stack_pointer = tracing_stack;

    for (uint16_t y = 0; y < height; y++) {
        for (uint16_t x = 0; x < width; x++) {
            // Collect all YES pixels into the stack
            if (image[idx_ref(x, y, width, height, 0, 0)] == 255) {
                  coord_t yes_pixel = {x, y};
                  *tracing_stack_pointer = yes_pixel;
                  tracing_stack_pointer++;  // increments by sizeof(coord_t)
            }
        }
    }

    // Empty the tracing stack one-by-one
    while (tracing_stack_pointer != tracing_stack) {
        tracing_stack_pointer--;
        coord_t known_edge = *tracing_stack_pointer;
        for (int k = 0; k < 8; k++) {
            coord_t dir_offs = neighbour_offsets_ref[k];
            coord_t neighbour = {
                known_edge.x + dir_offs.x, known_edge.y + dir_offs.y};

            // Clamp to edge to prevent the algorithm from leaving the image.
            // Not using the idx()-function, since we want to preserve the x
            // and y on their own, since the pixel might be added to the stack
            // in the end.
            if (neighbour.x < 0) neighbour.x = 0;
            if (neighbour.x >= width) neighbour.x = width - 1;
            if (neighbour.y < 0) neighbour.y = 0;
            if (neighbour.y >= height) neighbour.y = height - 1;

            // Only MAYBE neighbours are potential edges
            if (image[neighbour.y * width + neighbour.x] == 127) {
                  // Convert MAYBE to YES
                  image[neighbour.y * width + neighbour.x] = 255;

                  // Add the newly added pixel to stack, so changes will
                  // propagate
                  *tracing_stack_pointer = neighbour;
                  tracing_stack_pointer++;
            }
        }
    }
    // Clear all remaining MAYBE pixels to NO, these were not reachable from
    // any YES pixels
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            if (image[idx_ref(x, y, width, height, 0, 0)] == 127) {
                  image[idx_ref(x, y, width, height, 0, 0)] = 0;
            }
        }
    }
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
void
cannyEdgeDetection_ref(
    uint8_t* __restrict input, size_t width, size_t height,
    uint16_t threshold_lower, uint16_t threshold_upper,
    int gaussian_kernel_enabled,
    uint8_t* __restrict output) {
    size_t image_size = width * height;

    uint8_t* gaussian = malloc(image_size * sizeof(uint8_t));
    assert(gaussian);

    // Allocate arrays for intermediate results
    int16_t* sobel_x = malloc(image_size * sizeof(int16_t));
    assert(sobel_x);

    int16_t* sobel_y = malloc(image_size * sizeof(int16_t));
    assert(sobel_y);

    uint8_t* phase = malloc(image_size * sizeof(uint8_t));
    assert(phase);

    uint16_t* magnitude = malloc(image_size * sizeof(uint16_t));
    assert(magnitude);

    uint64_t times[5];
    // Canny edge detection algorithm consists of the following functions:
    times[0] = gettimemono_ns();
    if (gaussian_kernel_enabled) {
        gaussian3x3_ref(input, width, height, gaussian);
        sobel3x3_ref(gaussian, width, height, sobel_x, sobel_y);
    } else {
        sobel3x3_ref(input, width, height, sobel_x, sobel_y);
    }
    times[1] = gettimemono_ns();
    phaseAndMagnitude_ref(sobel_x, sobel_y, width, height, phase, magnitude);

    times[2] = gettimemono_ns();
    nonMaxSuppression_ref(
        magnitude, phase, width, height, threshold_lower, threshold_upper,
        output);

    times[3] = gettimemono_ns();
    edgeTracing_ref(output, width, height);  // modifies output in-place

    times[4] = gettimemono_ns();
    // Release intermediate arrays
    free(sobel_x);
    free(sobel_y);
    free(phase);
    free(magnitude);

    double diffs[4];
    for (int i = 0; i < 4; i++) {
        diffs[i] = times[i + 1] - times[i];
        diffs[i] /= 1000000.0;  // Convert ns to ms
    }
    /*    printf("Ref sobel3x3 time          : %0.3f ms\n", diffs[0]);
        printf("Ref phaseAndMagnitude time : %0.3f ms\n", diffs[1]);
        printf("Ref nonMaxSuppression time : %0.3f ms\n", diffs[2]);
        printf("Ref edgeTracing time       : %0.3f ms\n", diffs[3]);
        printf("Ref total time             : %0.3f ms\n", diffs[0] + diffs[1]
       + diffs[2] + diffs[3]);
    */
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
uint8_t*
read_pgm(char* path, size_t* output_width, size_t* output_height) {
    FILE* fp = fopen(path, "r");
    if (!fp) {
        printf("Unable to open file %s\n", path);
        return NULL;
    }
    char line[4096];
    int status = fscanf(fp, "%s", line);
    if (status != 1 && strcmp(line, "P2")) {
        printf("File is not valid PGM P2 file!\n");
        return NULL;
    }
    status = fscanf(fp, "%s", line);
    while (status == 1 && line[0] == '#') {
        char* fgets_out = fgets(line, 4095, fp);
        assert(fgets_out == line);
        status = fscanf(fp, "%s", line);
        assert(status == 1);
    }
    size_t max_value = 0;
    size_t width = 0;
    size_t height = 0;
    status = sscanf(line, "%zu", &width);
    assert(status == 1);
    status = fscanf(fp, "%zu", &height);
    assert(status == 1);
    status = fscanf(fp, "%zu", &max_value);
    assert(status == 1);

    uint8_t* output_image = malloc(width * height);
    assert(output_image);

    for (int n = 0; n < (width * height); n++) {
        uint8_t value = 0;
        status = fscanf(fp, "%hhu", &value);
        if (status == 1) {
            output_image[n] = value;
        }
    }
    fclose(fp);
    *output_width = width;
    *output_height = height;
    return output_image;
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
int
write_pgm(char* path, uint8_t* image, size_t width, size_t height) {
    FILE* fp = fopen(path, "w");
    fprintf(fp, "P2\n");

    fprintf(fp, "%zu %zu\n", width, height);
    fprintf(fp, "255\n");

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            fprintf(fp, "%hhu ", image[y * width + x]);
            if ((x + 1) % 127 == 0) {
                  // break up really long lines (1 line != 1 row pixels)
                  fprintf(fp, "\n");
            }
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
    return 0;
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
uint64_t
gettimemono_ns() {
    struct timeval current;
    gettimeofday(&current, NULL);
    return ((uint64_t)current.tv_sec * 1000000 + current.tv_usec) * 1000;
}

// ¤¤ DO NOT EDIT THIS FUNCTION ¤¤
int
validate_result(
    uint8_t* output, uint8_t* golden, size_t width, size_t height,
    uint8_t* fused) {
    int shouldve_been_white = 0;
    int shouldve_been_black = 0;
    int corrupted = 0;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            int n = y * width + x;
            if (output[n] != golden[n]) {
                  if (output[n] == 255) {
                      // Value should've been NO, setting it to dark-grey
                      fused[n] = 40;
                      shouldve_been_black++;
                  } else if (output[n] == 0) {
                      // Value should've been YES, setting it to light-grey
                      fused[n] = 200;
                      shouldve_been_white++;
                  } else {
                      // Only valid values are 0 and 255
                      fused[n] = 127;
                      corrupted++;
                  }
            } else {
                  fused[n] = output[n];
            }
        }
    }
    int failed = shouldve_been_white | shouldve_been_black | corrupted;
    if (failed) {
        printf(
            "Your image had %d black pixels that should've been white\n",
            shouldve_been_white);
        printf(
            "Your image had %d white pixels that should've been black\n",
            shouldve_been_black);
        printf(
            "Your image had %d corrupted pixels which were not 0 or 255\n",
            corrupted);
    }
    return failed;
}
