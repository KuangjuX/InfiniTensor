#include "core/common.h"
#include "core/constants.h"
#include "cuda/cuda_common.h"
#include <math.h>

using infini::E_CONSTANT;
constexpr unsigned int num_threads() { return 32 * 4; }
constexpr int thread_work_size() { return 4; }
constexpr int block_work_size() { return thread_work_size() * num_threads(); }

__global__ void _softmax_kernel1(float *input, float *output, size_t n) {
    float sum = 0.0f;
    for (size_t i = 0; i < n; ++i) {
        sum += pow(E_CONSTANT, input[i]);
    }
    *output = sum;
}

__global__ void _softmax_kernel2(float *input, float *output, size_t n) {
    float sum = *output;
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = pow(E_CONSTANT, input[i]) / sum;
    }
}

__global__ void _relu_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = max(input[i], float(0));
    }
}

__global__ void _sigmoid_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = 1 / (1 + pow(E_CONSTANT, -input[i]));
    }
}

__global__ void _hard_sigmoid_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = max(0.0f, min(1.0f, 0.2f * input[i] + 0.5f));
    }
}

__global__ void _hard_swish_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] =
            input[i] * max(0.f, min(1.f, (1.f / 6.f) * input[i] + 0.5f));
    }
}

__global__ void _tanh_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = (pow(E_CONSTANT, input[i]) - pow(E_CONSTANT, -input[i])) /
                    (pow(E_CONSTANT, input[i]) + pow(E_CONSTANT, -input[i]));
    }
}

__global__ void _abs_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = input[i] < 0 ? -input[i] : input[i];
    }
}

__global__ void _sqrt_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = sqrt(input[i]);
    }
}

__global__ void _gelu_kernel(float *input, float *output, size_t n) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    int stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride) {
        float x = input[i];
        output[i] = 0.5 * x * (1 + erf(x / sqrt(2.0f)));
    }
}

__global__ void _erf_kernel(float *input, float *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (int i = index; i < n; i += stride) {
        output[i] = erf(input[i]);
    }
}

template <typename T>
__global__ void _neg_kernel(T *input, T *output, size_t n) {
    size_t index = threadIdx.x + blockIdx.x * blockDim.x;
    size_t stride = blockDim.x * gridDim.x;
    for (size_t i = index; i < n; i += stride) {
        output[i] = -input[i];
    }
}

namespace infini {
void softmax_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _softmax_kernel1<<<1, 1>>>(input, output, num);
    _softmax_kernel2<<<gridsize, blocksize>>>(input, output, num);
}
void relu_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _relu_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void sigmoid_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _sigmoid_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void hard_sigmoid_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _hard_sigmoid_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void hard_swish_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _hard_swish_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void tanh_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _tanh_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void abs_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _abs_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void sqrt_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _sqrt_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void gelu_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _gelu_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void erf_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _erf_kernel<<<gridsize, blocksize>>>(input, output, num);
}
void neg_kernel(float *input, float *output, size_t num) {

    int blocksize = block_work_size();
    int gridsize = (num + block_work_size() - 1) / block_work_size();
    _neg_kernel<<<gridsize, blocksize>>>(input, output, num);
}
}; // namespace infini
