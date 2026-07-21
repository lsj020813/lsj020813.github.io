---
layout: post
title: "3/8 variant universe, liftover, cohort AF/MAF"
date: 2026-07-21 13:03:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 3/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: phenotype, 표본 동결과 GP90](/posts/knih-deeprvat-saige-chr22-02-phenotype-gp90/) · [다음글: annotation 복구와 common gene mask](/posts/knih-deeprvat-saige-chr22-04-annotation-common-mask/)
</nav>

# 9. variant universe의 진화: narrow smoke에서 R2-only broad universe로

## 9.1 초기 GT-only smoke BCF

| **항목** | **초기 smoke artifact** |
|----|----|
| 경로 | `qc_sites/chr22.raw.maf001.r2_08.gt.bcf` |
| 필터 | source INFO/MAF\>0, INFO/MAF\<0.001, INFO/R2≥0.8 |
| Variants | 34,591 |
| Samples | 87,430 |
| FORMAT | GT만 유지; DS/GP 제거 |
| GT-derived tag | AC/AN/AF/NS 재계산 |
| Expected vs actual AC correlation | 0.9954 |
| 최종 용도 | smoke/sensitivity only; primary로 사용 금지 |

이 파일은 DeepRVAT 변환 스키마와 기본 QC를 시험하는 데 유용했지만, source INFO/MAF로 이미 variant를 잘라낸 뒤에는 한국인 frozen cohort에서 rare/common을 다시 판정할 기회를 잃는다.

## 9.2 narrow liftover canary

| **항목**                   | **수** |
|----------------------------|--------|
| Source filtered variants   | 57,045 |
| GRCh38 mapped              | 54,164 |
| Rejected                   | 2,881  |
| Source/target REF mismatch | 0 / 0  |
| Canonical duplicate        | 0      |

이 narrow canary는 liftover와 GT/GP/DS audit에는 성공했지만, independent review에서 source MAF prefilter에 의한 variant-universe truncation이 지적됐다.

## 9.3 R2-only broad universe로 재구축

최종 production-like chr22에서는 source INFO/MAF cutoff를 제거하고 biallelic + R2≥0.8만 적용했다. rare 판정은 liftover 후 GP90 cohort AF/MAF로 다시 수행했다.

| **단계** | **Variant 수** | **의미** |
|----|----|----|
| Raw/R2-only source | 130,251 | source MAF로 자르지 않은 broad universe |
| GRCh38 mapped | 123,064 | 최종 variants.parquet/AF universe |
| Liftover rejected | 7,187 | mapping 불가; sensitivity 대상 |
| Final annotation rows | 160,656 | variant–gene 관계 확장 포함 |
| GP90 D90_MAF001 mask | 4,296 unique variants | canonical rare branch |
| GP90 D90_MAF01 mask | 6,618 unique variants | exploratory low-frequency branch |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>두 숫자 계열을 혼동하지 말 것</strong></p>
<p>57,045→54,164는 초기 source-MAF filtered narrow canary이고, 130,251→123,064는 source MAF cutoff를 제거한 최종 R2-only broad universe다. 서로 다른 universe이므로 variant count를 직접 증감률로 비교하면 안 된다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# 10. GRCh37→GRCh38 liftover와 reference QC

## 10.1 왜 liftover가 필요했는가

KNIH source는 GRCh37로 확인됐고 DeepRVAT annotation resource와 final gene mapping은 GRCh38에 맞춰야 했다. 같은 `22:position` 문자열도 build가 다르면 다른 genomic locus를 뜻하므로, annotation 전에 build를 고정해야 했다.

## 10.2 최종 broad liftover 결과

| **QC**                    | **결과**               |
|---------------------------|------------------------|
| LIFTOVER_DIRECTION        | PASS: GRCh37_TO_GRCh38 |
| SOURCE_INPUT_N            | 130,251                |
| LIFTOVER_MAPPED_N         | 123,064                |
| LIFTOVER_REJECTED_N       | 7,187                  |
| TARGET_NORMALIZED_N       | 123,064                |
| SOURCE_REF_MISMATCH_N     | 0                      |
| TARGET_REF_MISMATCH_N     | 0                      |
| DUPLICATE_CANONICAL_KEY_N | 0                      |
| FINAL_VCF / FINAL_BCF     | indexed, PASS          |

## 10.3 CrossMap 운영 문제

CrossMap 실행 중 reference FASTA가 read-only 위치에 있어 작업이 막혔고, writable copy를 만들어 해결했다. 이는 생물학적 오류가 아니라 workflow filesystem 문제였지만, 동일 reference checksum과 provenance를 유지해야 하는 이유를 보여준다.

> **UNRESOLVED**
>
> Rejected 7,187개 variant가 특정 gene·functional class에 편중됐는지까지는 현재 최종 감사에 포함되지 않았다. Genome-wide에서는 rejected-set enrichment를 별도 QC로 남겨야 한다.

# 11. cohort AF/MAF/MAC 재계산

## 11.1 source AF를 그대로 쓰지 않은 이유

source INFO/AF·MAF는 전체 imputation cohort, 다른 subset 또는 reference 정의를 반영할 수 있다. 이 프로젝트의 rare mask는 GP90 callable genotype과 frozen cohort에서 다시 계산해야 했다. 특히 KOR/EAS input-level adjustment 가능성의 첫 실제 구현이 cohort-specific AF/MAF였다.

## 11.2 GP90 cohort frequency 결과

| **항목**                  | **값**               |
|---------------------------|----------------------|
| variant_n                 | 123,064              |
| gp90_callable variants    | 123,064              |
| gp90_missing_any variants | 113,099              |
| gp90_af_nonmissing        | 123,064              |
| gt_callable               | 123,064              |
| ds_callable               | 123,064              |
| AF range                  | 0.0 – 0.991361614779 |
| MAF range                 | 0.0 – 0.499982234855 |

`gp90_missing_any=113,099`는 대부분의 site에서 적어도 한 개 이상의 sample–variant call이 GP90 미달로 missing 처리됐음을 의미한다. 반면 site-level AF는 모든 123,064개에서 계산 가능했다.

## 11.3 AF, MAF, MAF_MB와 external AF 분리

annotation recovery 과정에서 cohort-derived `af → AF`, `maf → MAF`, `maf_mb → MAF_MB`로 연결하고, external `gnomADg_AF`는 별도 feature로 유지했다. `gnomADg_AF`를 cohort AF의 대용으로 alias하지 않았다.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>왜 중요한가</strong></p>
<p>external AF와 KNIH cohort AF를 같은 열로 섞으면 pretrained feature의 의미가 달라지고, rare mask도 왜곡된다. 이번 복구는 ‘한국인 내부 frequency’와 ‘외부 reference frequency’를 분리했다는 점에서 향후 input-level adjustment 연구의 핵심 기반이다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 3/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: phenotype, 표본 동결과 GP90](/posts/knih-deeprvat-saige-chr22-02-phenotype-gp90/) · [다음글: annotation 복구와 common gene mask](/posts/knih-deeprvat-saige-chr22-04-annotation-common-mask/)
</nav>
