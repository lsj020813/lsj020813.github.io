---
layout: post
title: "6/8 DeepRVAT 실행과 무결성 감사"
date: 2026-07-21 13:06:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 6/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: SAIGE-GENE+ 실행과 오류 수정](/posts/knih-deeprvat-saige-chr22-05-saige/) · [다음글: 최종 결과, 해석, 한계와 다음 단계](/posts/knih-deeprvat-saige-chr22-07-results-interpretation/)
</nav>

# 15. DeepRVAT input preparation, config, patch, 실행

## 15.1 final input 연결

| **Input**                    | **최종 target/역할**                 |
|------------------------------|--------------------------------------|
| genotypes.h5                 | grouped sparse hard-call genotype    |
| phenotypes.parquet           | 58,639 phenotype/covariate rows      |
| variants.parquet             | 123,064 variant identity universe    |
| annotations.parquet          | 160,656 variant–gene annotation rows |
| protein_coding_genes.parquet | numeric ID↔Ensembl/gene name mapping |
| pretrained_models            | installed pretrained model directory |
| deeprvat_config.yaml         | chr22 association configuration      |

Final association folder에는 `ASSOC_INPUT_PREP.done`가 없었고, symlink target과 downstream output으로 provenance를 추적했다. 후속 generic chr1–21 script에는 done marker를 추가하는 방향으로 개선됐다.

## 15.2 HDF5 shape를 올바르게 읽는 법

| **항목** | **값** | **주의** |
|----|----|----|
| HDF5 samples | 87,430 unique | 전체 genotype cohort |
| genotype_matrix shape | (87,430, 32,534) | 32,534는 unique variant 수로 단정하면 안 됨; sparse padded width |
| variant_matrix shape | (87,430, 32,534) | genotype_matrix와 같은 sparse slot 구조 |
| variants.parquet rows | 123,064 | 실제 unique variant identity universe |
| Final xy samples | 58,639 | association phenotype subset |
| Final burden genes | 378 | gene-level score dimension |

## 15.3 grouped shard 준비

VCF에서 sparse genotype을 만들고 grouped shard 방식으로 변환했다. 최종 run은 grouped40 구조를 사용했다. shard가 0개이거나 `genotypes.h5`가 비어 있으면 중단하도록 prep script에 gate를 두었다.

## 15.4 config 조정

| **Config 항목** | **최종 값** | **해석** |
|----|----|----|
| Association chromosomes | \[22\] integer | string/int mismatch 방지 |
| Training chromosomes field | \[22\] | pretrained config 구조 유지 |
| do_scoretest | False | 이번 결과는 score test가 아니라 burden/regression |
| n_regression_chunks | 38 | 메모리/실행 조정 |
| association num_workers | 0 | multiprocessing 문제 회피 |
| training num_workers | 0 | 동일 |
| gt_file | genotypes.h5 | symlink input |
| annotation_file | annotations.parquet | final validated annotation |
| variant_file | variants.parquet | 123,064 universe |
| phenotype_file | phenotypes.parquet | 58,639 complete-case |

## 15.5 `associate.py` patch

``` python
try:
from seak import scoretest
except ImportError:
scoretest = None

X = X.reshape(X.shape[0], -1)
if len(y.shape) == 1:
y = np.expand_dims(y, axis=1)
```

`seak` fallback은 `do_scoretest=false`이므로 이번 burden OLS 결과에 직접 관여하지 않는다. 핵심은 1D phenotype `(n,)`을 `(n,1)`로 확장하는 patch였다.

| **Smoke test** | **1D patched y**      | **2D original y**     | **차이** |
|----------------|-----------------------|-----------------------|----------|
| Beta           | 0.6768972863719075    | 0.6768972863719075    | 0        |
| P-value        | 5.006351097612957e-42 | 5.006351097612957e-42 | 0        |
| Gene identity  | same                  | same                  | PASS     |

> **VERIFIED**
>
> 함수 수준에서는 1D shape patch가 2D 원래 입력과 동일 beta/p-value를 생성했다.

> **UNRESOLVED**
>
> 공식 upstream release와 전체 integration-level statistical equivalence를 증명한 것은 아니다.

## 15.6 sample/variant alignment audit

| **Audit**                           | **결과**        |
|-------------------------------------|-----------------|
| Phenotype rows / duplicate index    | 58,639 / 0      |
| Phenotype samples missing from HDF5 | 0               |
| HDF5 extra samples                  | 28,791          |
| xy sample IDs                       | 58,639 unique   |
| burden sample IDs                   | 58,639 unique   |
| xy↔burden missing                   | 0 / 0           |
| xy and burden order                 | identical       |
| y shape / NaN                       | (58,639,1) / 0  |
| x shape / NaN                       | (58,639,13) / 0 |
| burdens_average                     | (58,639,378,1)  |
| burdens                             | (58,639,378,30) |
| annotation IDs not in variants      | 0               |
| variant IDs not in annotation       | 0               |

## 15.7 DeepRVAT final output

| **산출물**                  | **결과**              |
|-----------------------------|-----------------------|
| Workflow                    | 48/48 steps complete  |
| Exit file                   | 0                     |
| burden_associations.parquet | 378 rows × 5 columns  |
| all_results.parquet         | 378 rows × 9 columns  |
| significant.parquet         | 0 rows                |
| Minimum raw p               | 0.0009552728955856164 |
| Minimum corrected p         | 0.361093154531363     |
| significant=True            | 0                     |

`significant.parquet` 0 rows는 failure가 아니라 corrected significant gene이 없다는 결과다. all_results가 정상적으로 존재하고 p-value가 수치형이며 workflow가 완료됐기 때문이다.


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 6/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: SAIGE-GENE+ 실행과 오류 수정](/posts/knih-deeprvat-saige-chr22-05-saige/) · [다음글: 최종 결과, 해석, 한계와 다음 단계](/posts/knih-deeprvat-saige-chr22-07-results-interpretation/)
</nav>
