"""
Description:
    Compute Lafon specificity of cooccurrent tokens of a given target.
"""

import string
import re
import itertools
import typing
import sys
import time, datetime

from collections import Counter, deque
from pathlib import Path
from math import log10


__punctuations = re.compile("[" + re.escape(string.punctuation) + "«»…" + "]+")

__tool_delta = {
    'itrameur': -1.0,
}

match_strategy = {
    'exact': str.__eq__,
    'regex': re.fullmatch
}


def progress(x):
    start = time.time()
    data = list(x) + [None]
    L = len(data) - 1
    for i, dat in enumerate(data):
        if i != L:
            print(f"{100*i/L:.2f}%", end='\r', file=sys.stderr)
            yield dat
        else:
            print(f"100.00% in {datetime.timedelta(seconds=time.time()-start)}", file=sys.stderr)
            return


def log_binomial(n: int, k: int) -> float:
    if k == 0 or k == n:
        return 0.0
    result = 0
    for i in range(min(k, n - k)):
        result += log10(n - i) - log10(i + 1)
    return result


def log_hypergeometric(T: int, t: int, F: int, f: int) -> float:
    return log_binomial(F, f) + log_binomial(T - F, t - f) - log_binomial(T, t)


def lafon_specificity(T, t, F, f, tool_emulation='None'):
    specif = log_hypergeometric(T, F, t, f) + __tool_delta.get(tool_emulation, 0.0)
    if log10(f + 1) > log10(t + 1) + log10(F + 1) - log10(T + 2):
        specif = -specif
    return specif


def read_corpus(
    sources,
    target,
    punctuations='ignore',
    case_sensitivity='sensitive',
    match=str.__eq__,
):
    tokens = []
    sentences = []
    target_indices = []
    start = end = 0

    ignore_punct = punctuations == 'ignore'
    fold = case_sensitivity in ('i', 'insensitive')

    for source in progress(sources):
        with open(source, encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if line:
                    if ignore_punct and __punctuations.fullmatch(line):
                        continue
                    if fold:
                        line = line.casefold()
                    tokens.append(line)
                    if match(target, line):
                        target_indices.append(end)
                    end += 1
                else:
                    if end > start:
                        sentences.append((start, end))
                        start = end
            if end > start:
                sentences.append((start, end))
                start = end

    return tokens, sentences, target_indices


def get_counts(tokens, sentences, target_indices, context_length, ignore_sentences=False, tool_emulation='None'):
    T = len(tokens)
    Fs = Counter(tokens)
    fs = Counter()
    tmp = Counter()

    indices = deque(target_indices)

    if not ignore_sentences:
        for start, end in sentences:
            loc = []
            while indices and start <= indices[0] < end:
                loc.append(indices.popleft())
            for idx in loc:
                for i in range(max(start, idx - context_length), min(end, idx + context_length + 1)):
                    if i != idx:
                        tmp[i] += 1
    else:
        for idx in indices:
            for i in range(max(0, idx - context_length), min(len(tokens), idx + context_length + 1)):
                if i != idx:
                    tmp[i] += 1

    if tool_emulation == 'itrameur':
        for i, c in tmp.items():
            fs[tokens[i]] += c
    else:
        for i in tmp:
            fs[tokens[i]] += 1

    t = sum(fs.values())
    return T, t, Fs, fs


def run(inputs, target, match_mode='exact', n_firsts=1000,
        punctuations='ignore', case_sensitivity='sensitive',
        context_length=10, min_frequency=1, min_cofrequency=1,
        ignore_sentences=False, tool_emulation='None'):

    print("Reading...", file=sys.stderr)

    tokens, sentences, target_indices = read_corpus(
        inputs, target, punctuations, case_sensitivity,
        match=match_strategy[match_mode]
    )

    T, t, Fs, fs = get_counts(
        tokens, sentences, target_indices, context_length,
        ignore_sentences, tool_emulation
    )

    print("Computing specificities...", file=sys.stderr)

    data = []
    for token, cofreq in fs.items():
        if Fs[token] >= min_frequency and cofreq >= min_cofrequency:
            spec = lafon_specificity(T, t, Fs[token], cofreq, tool_emulation)
            data.append((token, Fs[token], cofreq, spec))

    data.sort(key=lambda x: -x[3])

    print("token\tcorpus_size\tcontext_size\tfrequency\tcofrequency\tspecificity")
    for token, F, f, s in data[:n_firsts]:
        print(f"{token}\t{T}\t{t}\t{F}\t{f}\t{s:.2f}")


def main(argv=None):
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('inputs', nargs='+')
    parser.add_argument('--target', required=True)
    parser.add_argument('--match-mode', choices=('exact', 'regex'), default='exact')
    parser.add_argument('-N', '--n-firsts', type=int, default=1000)
    parser.add_argument('-p', '--punctuations', choices=('ignore', 'acknowledge'), default='ignore')
    parser.add_argument('-s', '--case-sensitivity', choices=('sensitive', 's', 'insensitive', 'i'), default='sensitive')
    parser.add_argument('-l', '--context-length', type=int, default=10)
    parser.add_argument('-f', '--min-frequency', type=int, default=1)
    parser.add_argument('-c', '--min-cofrequency', type=int, default=1)
    parser.add_argument('-i', '--ignore-sentences', action='store_true')
    parser.add_argument('-t', '--tool-emulation', choices=('None', 'itrameur', 'TXM'), default='None')

    args = parser.parse_args(argv)

    # 🔧 CORRECTION : dossiers → fichiers .txt
    expanded = []
    for inp in args.inputs:
        p = Path(inp)
        if p.is_dir():
            expanded.extend(sorted(p.glob("*.txt")))
        else:
            expanded.append(p)

    args.inputs = expanded

    run(**vars(args))


if __name__ == '__main__':
    main()
