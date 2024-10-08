/**
 * llama.cpp - commit 8962422b1c6f9b8b15f5aeaea42600bcc2d44177 - do not edit this file without generating a patch
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

#pragma once

#include "llama-impl.h"

struct llama_vocab;
struct llama_sampling;

struct llama_grammar {
    const llama_grammar_rules  rules;
          llama_grammar_stacks stacks;

    // buffer for partially generated UTF-8 sequence from accepted tokens
    llama_partial_utf8 partial_utf8;
};

//
// internal API
//

struct llama_grammar * llama_grammar_init_impl(
            const llama_grammar_element ** rules,
                                 size_t    n_rules,
                                 size_t    start_rule_index);

void llama_grammar_free_impl(struct llama_grammar * grammar);

struct llama_grammar * llama_grammar_copy_impl(const struct llama_grammar * grammar);

void llama_grammar_sample_impl(
        const struct llama_grammar * grammar,
          const struct llama_vocab * vocab,
       const struct llama_sampling * smpl,
            llama_token_data_array * candidates);

void llama_grammar_accept_token_impl(
              struct llama_grammar * grammar,
          const struct llama_vocab * vocab,
       const struct llama_sampling * smpl,
                       llama_token   token);
