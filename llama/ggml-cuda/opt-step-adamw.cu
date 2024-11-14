/**
 * llama.cpp - commit 4a8ccb37ad9c9027cbcfd5548c19cdffe48d5197 - do not edit this file
 *
 * MIT License
 *
 * Copyright (c) 2023-2024 The ggml authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "opt-step-adamw.cuh"

#include <cstdint>

static __global__ void opt_step_adamw_f32(
    float * __restrict__ x, const float * __restrict__ g, float * __restrict__ g_m, float * __restrict__ g_v, const int64_t k,
    const float alpha, const float beta1, const float beta2, const float eps, const float wd,
    const float beta1h, const float beta2h) {

    const int64_t i = (int64_t) blockIdx.x*blockDim.x + threadIdx.x;

    if (i >= k) {
        return;
    }

    const float gi = g[i];
    const float gmi = g_m[i]*beta1 +    gi*(1.0f - beta1);
    const float gvi = g_v[i]*beta2 + gi*gi*(1.0f - beta2);

    g_m[i] = gmi;
    g_v[i] = gvi;

    const float mh =       gmi*beta1h;
    const float vh = sqrtf(gvi*beta2h) + eps;

    x[i] = x[i]*(1.0f - alpha*wd) - mh/vh;
}

static void opt_step_adamw_f32_cuda(
    float * x, const float * g, float * g_m, float * g_v, const int64_t k,
    const float alpha, const float beta1, const float beta2, const float eps, const float wd,
    const float beta1h, const float beta2h, cudaStream_t stream) {

    const dim3 block_dims(CUDA_OPT_STEP_ADAMW_BLOCK_SIZE, 1, 1);
    const dim3 block_nums((k + CUDA_OPT_STEP_ADAMW_BLOCK_SIZE - 1) / CUDA_OPT_STEP_ADAMW_BLOCK_SIZE, 1, 1);
    opt_step_adamw_f32<<<block_nums, block_dims, 0, stream>>>(x, g, g_m, g_v, k, alpha, beta1, beta2, eps, wd, beta1h, beta2h);
}

void ggml_cuda_opt_step_adamw(ggml_backend_cuda_context & ctx, ggml_tensor * dst) {
    const ggml_tensor * src0        = dst->src[0];
    const ggml_tensor * src0_grad   = dst->src[1];
    const ggml_tensor * src0_grad_m = dst->src[2];
    const ggml_tensor * src0_grad_v = dst->src[3];

    GGML_ASSERT(src0->type        == GGML_TYPE_F32);
    GGML_ASSERT(src0_grad->type   == GGML_TYPE_F32);
    GGML_ASSERT(src0_grad_m->type == GGML_TYPE_F32);
    GGML_ASSERT(src0_grad_v->type == GGML_TYPE_F32);
    GGML_ASSERT(ggml_is_contiguous(src0));
    GGML_ASSERT(ggml_is_contiguous(src0_grad));
    GGML_ASSERT(ggml_is_contiguous(src0_grad_m));
    GGML_ASSERT(ggml_is_contiguous(src0_grad_v));
    GGML_ASSERT(ggml_are_same_shape(src0, src0_grad));
    GGML_ASSERT(ggml_are_same_shape(src0, src0_grad_m));
    GGML_ASSERT(ggml_are_same_shape(src0, src0_grad_v));

    float       * src0_d        = (float       *) src0->data;
    const float * src0_grad_d   = (const float *) src0_grad->data;
    float       * src0_grad_m_d = (float       *) src0_grad_m->data;
    float       * src0_grad_v_d = (float       *) src0_grad_v->data;

    cudaStream_t stream = ctx.stream();

    const int64_t ne = ggml_nelements(src0);

    int64_t iter;  memcpy(&iter,  &dst->op_params[0], sizeof(int64_t));
    float   alpha; memcpy(&alpha, &dst->op_params[2], sizeof(float));
    float   beta1; memcpy(&beta1, &dst->op_params[3], sizeof(float));
    float   beta2; memcpy(&beta2, &dst->op_params[4], sizeof(float));
    float   eps;   memcpy(&eps,   &dst->op_params[5], sizeof(float));
    float   wd;    memcpy(&wd,    &dst->op_params[6], sizeof(float));

    const float beta1h  = alpha/(1.0f - powf(beta1, iter));
    const float beta2h  =  1.0f/(1.0f - powf(beta2, iter));

    opt_step_adamw_f32_cuda(src0_d, src0_grad_d, src0_grad_m_d, src0_grad_v_d, ne, alpha, beta1, beta2, eps, wd, beta1h, beta2h, stream);

    iter++;
    memcpy(&dst->op_params[0], &iter, sizeof(int64_t));
}
