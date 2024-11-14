// TODO: this is a temporary wrapper to allow calling C++ code from CGo
#include "sampling.h"
#include "sampling_ext.h"

struct common_sampler *common_sampler_cinit(
    const struct llama_model *model, struct common_sampler_cparams *params)
{
    try {
        common_sampler_params sparams;
        sparams.top_k = params->top_k;
        sparams.top_p = params->top_p;
        sparams.min_p = params->min_p;
        sparams.xtc_probability = params->xtc_probability;
        sparams.xtc_threshold = params->xtc_threshold;
        sparams.typ_p = params->typical_p;
        sparams.temp = params->temp;
        sparams.penalty_last_n = params->penalty_last_n;
        sparams.penalty_repeat = params->penalty_repeat;
        sparams.penalty_freq = params->penalty_freq;
        sparams.penalty_present = params->penalty_present;
        sparams.mirostat = params->mirostat;
        sparams.mirostat_tau = params->mirostat_tau;
        sparams.mirostat_eta = params->mirostat_eta;
        sparams.penalize_nl = params->penalize_nl;
        sparams.seed = params->seed;
        sparams.grammar = params->grammar;
        return common_sampler_init(model, sparams);
    } catch (const std::exception & err) {
        return nullptr;
    }
}

void common_sampler_cfree(struct common_sampler *sampler)
{
    common_sampler_free(sampler);
}

void common_sampler_creset(struct common_sampler *sampler)
{
    common_sampler_free(sampler);
}

llama_token common_sampler_csample(
    struct common_sampler *sampler,
    struct llama_context *ctx_main,
    int idx)
{
    return common_sampler_sample(sampler, ctx_main, idx);
}

void common_sampler_caccept(
    struct common_sampler *sampler,
    llama_token id,
    bool apply_grammar)
{
    common_sampler_accept(sampler, id, apply_grammar);
}
