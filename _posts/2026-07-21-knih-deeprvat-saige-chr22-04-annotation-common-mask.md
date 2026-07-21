---
layout: post
title: "4/8 annotation 복구와 common gene mask"
date: 2026-07-21 13:04:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 4/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: variant universe, liftover와 AF/MAF](/posts/knih-deeprvat-saige-chr22-03-variant-universe-liftover-af/) · [다음글: SAIGE-GENE+ 실행과 오류 수정](/posts/knih-deeprvat-saige-chr22-05-saige/)
</nav>

# 12. annotation resource 준비, 실패, 복구

## 12.1 준비한 주요 resource

| **Resource/도구** | **상태·기록** |
|----|----|
| CADD SNV/indel | 다운로드 완료 |
| SpliceAI SNV/indel | 다운로드 완료 |
| AlphaMissense | 다운로드 완료 |
| GENCODE v44 | 다운로드 완료 |
| AbSplice | zip size mismatch 확인 후 명시적 override와 unzip 완료 |
| VEP | READY |
| kipoi-veff2 / DeepRiPe | READY |
| DeepSEA / DeepRiPe / AbSplice annotation | 최종 pipeline에 포함 |

AbSplice archive는 기록된 크기 21,710,184,861 bytes와 예상 23,305,819,000 bytes가 달랐다. 무조건 무시하지 않고 mismatch를 기록한 뒤 명시적 override로 진행했다. 최종 resource checksum/version manifest는 genome-wide 단계에서 다시 고정할 필요가 있다.

## 12.2 annotation 1차 실패와 HOLD

초기 chr22 annotation이 full pretrained feature contract를 만족하지 못하면서 프로젝트는 HOLD로 전환됐다. 당시 association을 계속 돌리지 않고 다음 gate를 먼저 요구했다.

- annotations.parquet provenance 확정

- PrimateAI canary

- AlphaMissense canary

- cohort AF/MAF/MAF_MB 생성

- YAML source column 존재 확인

- select/rename/fill 재실행

- id, gene_id, MAF, MAF_MB, PrimateAI_score, alphamissense 확인

- row count, unique variant key, unique variant–gene pair, gene_id missingness 보고

이 HOLD는 중요한 연구 결정이었다. feature가 빠진 reduced model을 pretrained full-feature 결과처럼 해석하지 않기 위해서였다.

## 12.3 ID truncation과 chromosome normalization

중간 annotation에서 variant ID가 잘리거나 `chr22`/`22` 표기가 어긋나는 문제가 발견됐다. canonical variant key를 이용해 ID를 복구하고, variants parquet와 일치하는 chromosome representation으로 정규화했다.

| **스크립트** | **역할** |
|----|----|
| repair_annotation_ids_from_variant_keys.py | canonical key로 annotation ID 복구 |
| normalize_annotation_chrom_for_variants.py | annotation chromosome 표기 정렬 |
| postprocess_chr22_annotation_absplice_v2.py | AbSplice 및 후처리 |
| validate_final_annotation.py | final schema·completeness·duplicate gate |

# 13. final annotation integrity와 common gene mask

## 13.1 final annotation QC

| **Gate**                    | **결과**                     |
|-----------------------------|------------------------------|
| Rows / ID_PRESENT           | 160,656 / 160,656 nonmissing |
| GENE_ASSIGNMENT_PRESENT     | 85,205 assigned rows         |
| DUPLICATE_ID_GENE           | 0                            |
| PRETRAINED_FEATURES_PRESENT | 34 features, missing_n=0     |
| CADD_PHRED                  | PASS                         |
| AbSplice_DNA                | PASS                         |
| AF / MAF / MAF_MB           | PASS                         |
| PrimateAI_score             | PASS                         |
| alphamissense               | PASS                         |
| gnomADg_AF                  | PASS                         |
| DeepRipe_plus_MBNL1_parclip | PASS                         |
| contract validation exit    | 0                            |

추가 감사에서 annotation IDs not in variants=0, variant IDs not in annotations=0이었다. annotation row가 variant 123,064개보다 많은 것은 variant–gene 관계로 확장됐기 때문이다.

## 13.2 common gene mask branch

| **Branch** | **Gene-mask N** | **Variant N** | **Total AC** | **Carrier cells** | **상태** |
|----|----|----|----|----|----|
| D90_MAF001 | 376 | 4,296 | 188,771 | 188,687 | PASS |
| D90_MAF01 | 381 | 6,618 | 1,152,076 | 1,149,864 | PASS |
| D95_MAF001 | 376 | 4,338 | 188,411 | 188,334 | PASS |
| D95_MAF01 | 381 | 6,550 | 1,079,242 | 1,077,317 | PASS |

Primary final comparison은 `D90_MAF001`과 annotation group `CADD_PHRED_GT5`를 사용했다. 여기서 carrier cells는 unique people 수가 아니라 sample–variant non-reference 조합 수다.

## 13.3 group file에서 SAIGE test까지 감소

| **단위** | **수** | **설명** |
|----|----|----|
| Group file genes | 376 | mask에 gene entry 존재 |
| SAIGE markerList regions | 372 | SAIGE 내부 testability 후 |
| SAIGE result regions | 372 | markerList와 1:1 일치 |
| Group membership variant entries | 4,960 | 한 variant가 여러 gene에 포함될 수 있음 |
| MarkerList membership entries | 4,181 | 최종 set test 사용 entries |
| MarkerList unique variants | 3,629 | gene 중복 제거한 unique key |


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 4/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: variant universe, liftover와 AF/MAF](/posts/knih-deeprvat-saige-chr22-03-variant-universe-liftover-af/) · [다음글: SAIGE-GENE+ 실행과 오류 수정](/posts/knih-deeprvat-saige-chr22-05-saige/)
</nav>
