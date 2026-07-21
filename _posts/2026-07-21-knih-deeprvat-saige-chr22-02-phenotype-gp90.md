---
layout: post
title: "2/8 phenotype, 표본 동결, GT·DS·GP 및 GP90 결정"
date: 2026-07-21 13:02:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 2/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 연구 질문과 사전 타당성](/posts/knih-deeprvat-saige-chr22-01-feasibility/) · [다음글: variant universe, liftover, cohort AF/MAF](/posts/knih-deeprvat-saige-chr22-03-variant-universe-liftover-af/)
</nav>

# 6. phenotype·공변량·표본 동결

## 6.1 원변수와 결측 처리

원 phenotype은 `CT1_TCHL`이었다. 코드북의 특수값은 실제 수치로 해석하지 않고 missing으로 전환했다.

| **값**                      | **코드북 의미**         | **분석 처리** |
|-----------------------------|-------------------------|---------------|
| 66666                       | 조사 안 함              | NA            |
| 77777                       | 해당 없음               | NA            |
| 99999                       | 미상·무응답·미측정·결측 | NA            |
| 빈 문자열·비수치·non-finite | 유효한 측정값 아님      | NA            |

자동 생리적 범위 필터, winsorization, 결과 기반 outlier 제거는 적용하지 않는 원칙이었다.

## 6.2 TCHL_raw와 TCHL_rint

동일한 최종 표본에서 원값 `TCHL_raw`를 보존하고 average-rank inverse normal transformation을 한 번 적용해 `TCHL_rint`를 만들었다. Primary는 TCHL_rint, sensitivity는 TCHL_raw였다. SAIGE에서는 다시 inverse normalization하지 않도록 `invNormalize=FALSE`를 사용했다.

``` text
TCHL_raw = 원래 total cholesterol 측정값
TCHL_rint = 최종 frozen sample에서 rank를 계산한 뒤 정규점수로 변환
```

따라서 beta는 mg/dL 변화량이 아니다. 특히 SAIGE와 DeepRVAT의 burden score scale도 다르므로 beta 절대크기를 방법 간 비교하면 안 된다.

## 6.3 표본과 ID map

| **항목**                                                  | **수**          |
|-----------------------------------------------------------|-----------------|
| Genotype VCF samples                                      | 87,430          |
| Phenotype-side records in earlier mapping summary         | 61,562          |
| One-to-one genotype–phenotype match / final complete-case | 58,639          |
| Ambiguous mapping                                         | 0               |
| Final phenotype samples present in lifted VCF             | 58,639 / 58,639 |

검증된 `genotype_to_ct.map.tsv`만 사용하고 prefix/suffix 임의 절단은 금지했다. 최종 association audit에서 xy와 burden sample IDs는 모두 58,639개, 중복 0, 상호 누락 0, 순서 동일이었다.

## 6.4 공변량

계획상 core model은 centered age, centered age², sex, PC1–PC10이었다. 실제 association zarr의 X shape는 `(58639, 13)`으로, age·age²·sex·10 PCs에 해당하는 13개 열 규모와 일치한다. 그러나 현재 감사 기록만으로 실제 age centering 구현 여부까지 독립 확인되지는 않았으므로 최종 genome-wide 보고 전 config/schema를 다시 고정해야 한다.

> **UNRESOLVED**
>
> 기관·조사연도 sensitivity와 TCHL_raw sensitivity가 최종 chr22 결과까지 실제 실행됐다는 증거는 현재 최종 결과 문서에 없다. 계획된 branch와 실행 완료 branch를 구분한다.

# 7. KNIH chr22 VCF의 실체와 imputation metadata

## 7.1 데이터 생성 계통

``` text
KCHIP array
→ phasing
→ Minimac v4.1.4 imputation
→ FORMAT/GT, FORMAT/DS, FORMAT/GP
→ INFO/R2, ER2, IMPUTED, TYPED, AF, MAF
```

narrow chr22 canary에서 확인된 54,164개 site는 모두 `IMPUTED=1`이었다. 즉 이 분석은 직접 sequencing으로 확인한 rare variant가 아니라 imputation posterior에 크게 의존한다.

## 7.2 GT·DS·GP의 의미

| **필드** | **의미** | **장점** | **한계** |
|----|----|----|----|
| GT | best-guess genotype; 0/0, 0/1, 1/1 | DeepRVAT sparse hard-call 변환 가능 | posterior uncertainty를 숨김 |
| DS | ALT allele dosage; 0~2 실수 | imputation uncertainty 일부 보존, SAIGE 지원 | DeepRVAT native sparse schema와 직접 호환 미확인 |
| GP | P(0/0), P(0/1), P(1/1) | hard-call 확신도 평가 가능 | threshold 미달을 어떻게 처리할지 사전 규칙 필요 |
| R2 | site-level imputation quality | 변이 단위 broad QC | 개별 sample의 carrier confidence를 보장하지 않음 |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>핵심 구분</strong></p>
<p>R2≥0.8은 ‘이 variant가 전체적으로 얼마나 잘 impute되었는가’를 보는 site-level gate이고, GP≥0.90은 ‘이 사람의 이 variant genotype을 얼마나 확신하는가’를 보는 cell-level gate다. 둘 중 하나만으로는 충분하지 않다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# 8. GT·DS·GP 비교와 GP90 정책 확정

## 8.1 왜 raw GT를 바로 쓰지 않았는가

독립 검수는 best-guess GT가 항상 채워져 있으면 call rate 100%도 아무 의미가 없다고 지적했다. rare-variant test에서는 소수 carrier가 결과를 주도하므로, 확률 0.55의 0/1 call과 확률 0.99의 0/1 call을 같은 carrier로 취급하면 위험하다.

## 8.2 narrow chr22 representation audit

| **집계 항목** | **RAW/GT** | **GP90** | **DS** | **해석** |
|----|----|----|----|----|
| Callable sites | 54,164 | 54,164 | 54,164 | 세 representation 모두 site-level 산출 가능 |
| Monomorphic sites | 1,035 | 기록상 별도 값 미제공 | 해당 없음/연속 dosage | raw narrow universe에 단형성 존재 |
| 0\<MAF\<0.001 sites | 32,572 | 34,990 | 32,552 | GP missing 처리로 AN·MAF가 바뀌어 rare 분류 수가 달라짐 |
| 0\<MAF\<0.01 sites | 53,119 | 52,787 | 53,873 | threshold와 representation에 따라 universe 변화 |
| Missing genotype cells | raw GT는 거의 채워짐 | 4,348,205 | 0 | GP90은 불확실 call을 missing으로 전환 |
| GT–GP90 carrier concordance | — | 1.00000000 | — | GP90으로 남은 carrier는 raw GT carrier와 일치; 미달 carrier는 제거 |

추가 집계에서 raw GT carrier cell은 약 9,256,700개였고 GP80 branch는 약 8,166,808개로 줄었다. GP90 감사에서는 low-confidence carrier cell 1,649,406개가 확인됐으며, 그중 heterozygous call 1,642,683개, homozygous-alt call 6,723개였다. 이 수치는 raw GT를 그대로 primary에 사용할 수 없다는 직접 근거가 됐다.

> **VERIFIED**
>
> GP90으로 남은 carrier와 raw GT의 carrier identity가 일치한다는 것은 GP90이 genotype allele를 바꾼 것이 아니라, posterior가 낮은 genotype을 missing 처리한 정책임을 뜻한다.

## 8.3 GP90을 선택한 이유

- GP80은 불확실 call을 상당수 남겨 rare carrier false positive 위험이 더 컸다.

- GP90은 commonly used conservative posterior cutoff로, 불확실 call을 대량 제거하면서도 chr22 gene mask가 붕괴하지 않았다.

- GP95는 더 엄격한 sensitivity로 유지해 결과가 confidence threshold에 얼마나 민감한지 확인하도록 했다.

- GP99는 매우 엄격해 imputed rare variant의 callable carrier와 gene testability를 과도하게 잃을 가능성이 있어 primary로 채택하지 않았다.

- RAW_GT는 공급자가 생성한 best-guess call의 진단용 비교로만 유지했다.

- DS는 uncertainty-aware representation이므로 SAIGE 전용 sensitivity/실행 branch로 유지했다.

## 8.4 최종 genotype policy

| **Branch** | **정책** | **용도** | **최종 상태** |
|----|----|----|----|
| GP90 / D90 | max(GP)≥0.90이면 best-guess ALT count 0/1/2, 미달은 missing | DeepRVAT primary hard-call, cohort AF, common mask | 실행됨 |
| GP95 / D95 | max(GP)≥0.95, 미달 missing | strict sensitivity | mask branch 생성; association 완료 여부 미확인 |
| RAW_GT | VCF best-guess GT 그대로 | diagnostic/feasibility only | primary에서 제외 |
| DS | 0~2 dosage | SAIGE imputation-aware branch | 최종 SAIGE chr22 run에 사용 |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>MAF count가 threshold에 따라 단조롭게 줄지 않을 수 있는 이유</strong></p>
<p>GP threshold를 높이면 carrier cell은 줄지만 AN도 달라진다. 어떤 variant는 GP90에서 MAF≥0.001이었다가 GP95에서 MAF&lt;0.001로 재분류될 수 있다. 실제로 D95_MAF001 variant 수(4,338)가 D90_MAF001(4,296)보다 약간 많았으므로, ‘엄격한 GP이면 모든 rare-site count가 반드시 감소한다’고 가정하면 안 된다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 2/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 연구 질문과 사전 타당성](/posts/knih-deeprvat-saige-chr22-01-feasibility/) · [다음글: variant universe, liftover, cohort AF/MAF](/posts/knih-deeprvat-saige-chr22-03-variant-universe-liftover-af/)
</nav>
