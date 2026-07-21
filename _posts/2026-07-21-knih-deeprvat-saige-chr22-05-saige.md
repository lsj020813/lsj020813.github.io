---
layout: post
title: "5/8 SAIGE-GENE+ 실행과 오류 수정"
date: 2026-07-21 13:05:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 5/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: annotation 복구와 common gene mask](/posts/knih-deeprvat-saige-chr22-04-annotation-common-mask/) · [다음글: DeepRVAT 실행과 무결성 감사](/posts/knih-deeprvat-saige-chr22-06-deeprvat/)
</nav>

# 14. SAIGE Step1/Step2 실행과 오류 수정

## 14.1 Step1 null model

SAIGE Step1은 frozen phenotype·sample·covariate와 일치해야 하며, TCHL_rint를 이미 외부에서 만들었기 때문에 `invNormalize=FALSE`로 운용했다. 초기 retry2에서는 `.rda`가 생성됐지만 `varianceRatio.txt`가 0 byte여서 Step2를 진행하지 않는 BLOCKED 상태가 있었다.

> **UNRESOLVED**
>
> 최종 성공 Step2가 사용한 Step1 variance-ratio 파일의 정확한 재생성·승인 과정은 현재 제공된 최종 감사 문서에 완전히 기록돼 있지 않다. 최종 output은 생성됐지만 Step1 categorical variance-ratio/GRM/LOCO 계약은 genome-wide 전에 다시 독립 검증해야 한다.

## 14.2 최종 Step2 설정

| **설정**              | **값**         |
|-----------------------|----------------|
| Phenotype             | TCHL_rint      |
| Chromosome            | 22             |
| VCF field             | DS             |
| Group mask            | D90_MAF001     |
| max MAF in group test | 0.001          |
| Annotation group      | CADD_PHRED_GT5 |
| Allele order          | ref-first      |

## 14.3 marker prefix 오류

``` text
초기 group marker : chr22:pos:ref:alt
VCF CHROM : 22
SAIGE --chrom : 22
VCF ID : .
결과 : exit 0, set output 0 byte
```

프로그램 종료가 정상이어도 group marker가 VCF와 매칭되지 않아 실제 gene test는 수행되지 않았다. 이를 biological negative로 오해할 수 있는 치명적 상황이었다.

``` bash
perl -pe 's/\bchr22:/22:/g' D90_MAF001.group.txt > D90_MAF001.saige_vcf_chrom22.group.txt
```

| **Output**       | **수정 후 결과**                   |
|------------------|------------------------------------|
| Set-level result | 373 lines = header + 372 gene rows |
| MarkerList       | 373 lines = header + 372 regions   |
| SingleAssoc      | 3,504 lines = header + 3,503 rows  |

## 14.4 set-level과 singleAssoc의 관계

Set result와 markerList는 region 수 및 rare/ultra-rare count mismatch 0으로 일치했다. 그러나 singleAssoc unique variants는 markerList와 완전히 1:1이 아니었다.

| **항목**                                    | **수** |
|---------------------------------------------|--------|
| MarkerList unique keys                      | 3,629  |
| SingleAssoc unique keys                     | 2,820  |
| MarkerList에 있으나 singleAssoc에 없는 keys | 810    |
| SingleAssoc에만 있는 keys                   | 1      |
| Multiple gene membership marker keys        | 512    |
| Max membership count                        | 4      |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>현재 해석 경계</strong></p>
<p>주 비교는 gene-level set result이므로 이 불일치가 최종 372-gene 비교를 직접 무효화하지는 않는다. 하지만 single-variant 해석, carrier audit, beta 방향 검증에는 추가 reconciliation이 필요하다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 5/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: annotation 복구와 common gene mask](/posts/knih-deeprvat-saige-chr22-04-annotation-common-mask/) · [다음글: DeepRVAT 실행과 무결성 감사](/posts/knih-deeprvat-saige-chr22-06-deeprvat/)
</nav>
