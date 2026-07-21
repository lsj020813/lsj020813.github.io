---
layout: post
title: "1/8 연구 질문과 array-imputed 데이터 사전 타당성"
date: 2026-07-21 13:01:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 1/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [다음글: phenotype, 표본 동결, GT·DS·GP 및 GP90 결정](/posts/knih-deeprvat-saige-chr22-02-phenotype-gp90/)
</nav>

**KNIH array-imputed genotype 기반\
DeepRVAT–SAIGE-GENE+ chr22 프로젝트**

사전 타당성 판단부터 GP 정책 확정, 전처리, annotation, association,\
오류 수정, 무결성 감사와 최종 해석까지의 완전 통합 기록

기준 시점: 2026-07-21 KST\
대상 phenotype: CT1_TCHL → TCHL_raw / TCHL_rint\
기술 canary: chromosome 22\
분석 표본: 58,639명\
문서 성격: 발표용 서사 + 기술 감사 + Evidence Log

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>문서 범위와 정직한 한계</strong></p>
<p>이 문서는 현재 접근 가능한 계획서, 독립 검수, 서버 handoff, phenotype 코드, chr22 최종 감사 보고서, 최종 결과 보고서 및 이전 세션의 비식별 집계 기록을 합쳐 복원한 완성본이다. 원자료·개별 표본·carrier 목록은 포함하지 않는다. 기록에서 직접 확인되지 않은 세부 사항은 VERIFIED로 승격하지 않고 UNRESOLVED 또는 INFERENCE로 표시했다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# 목차

1.  0\. 한눈에 보는 최종 결론

2.  1\. 최종 연구 질문과 chr22 프로젝트의 역할

3.  2\. 전체 작업의 시간순 지도

4.  3\. Phase 0: array-imputed 데이터를 DeepRVAT에 넣을 수 있는가

5.  4\. 보안·재현성·운영 구조 설계

6.  5\. 연구 설계의 초기안, 독립 검수, 최종 수정

7.  6\. phenotype·공변량·표본 동결

8.  7\. KNIH chr22 VCF의 실체와 imputation metadata

9.  8\. GT·DS·GP 비교와 GP90 정책 확정

10. 9\. variant universe의 진화: narrow smoke에서 R2-only broad universe로

11. 10\. GRCh37→GRCh38 liftover와 reference QC

12. 11\. cohort AF/MAF/MAC 재계산

13. 12\. annotation resource 준비, 실패, 복구

14. 13\. final annotation integrity와 common gene mask

15. 14\. SAIGE Step1/Step2 실행과 오류 수정

16. 15\. DeepRVAT input preparation, config, patch, 실행

17. 16\. 최종 결과 harmonization과 통계 비교

18. 17\. 주요 후보와 방법론적 해석

19. 18\. 결과 무결성 감사와 잔여 위험

20. 19\. 무엇을 말할 수 있고 무엇을 말하면 안 되는가

21. 20\. 발표용 완성 서사

22. 21\. 다음 단계와 연구 질문의 재정의

23. 부록 A. 핵심 수치 타임라인

24. 부록 B. 경로·스크립트·산출물 manifest

25. 부록 C. 설계 결정 로그

26. 부록 D. Evidence Log

# 0. 한눈에 보는 최종 결론

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>한 문장 결론</strong></p>
<p>KNIH array-imputed genotype을 GP confidence gate와 cohort-specific frequency, GRCh38 annotation, 공통 gene mask를 거쳐 pretrained DeepRVAT에 입력하고 chr22 gene-level association까지 수행하는 것은 기술적으로 가능함을 실증했다. 그러나 최종 chr22 비교는 SAIGE의 DS dosage와 DeepRVAT의 GP90 hard-call burden을 비교한 것이므로 순수한 방법 차이만 분리하지 못하며, 양쪽 모두 Bonferroni 유의 gene이 없어 ancestry-transfer 성능 저하를 입증하지는 못했다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

| **판정 영역** | **최종 판정** | **핵심 근거** |
|----|----|----|
| **Array→DeepRVAT 기술 입력** | PASS_WITH_WARNINGS | HDF5/Parquet 생성, annotation 34 features 통과, DeepRVAT 48/48 steps 완료 |
| **Imputed genotype 정책** | GP90 primary 확정 | RAW_GT의 불확실 carrier 다수 확인; GP90 미달 call은 missing 처리 |
| **Genome build/variant key** | PASS | GRCh37→GRCh38, target REF mismatch 0, canonical duplicate 0 |
| **Phenotype/sample alignment** | PASS | TCHL_rint 58,639명, xy와 burden sample 순서 동일 |
| **SAIGE 실행** | PASS after correction | `chr22:`→`22:` marker prefix 수정 후 372 gene rows |
| **DeepRVAT 실행** | PASS_WITH_WARNINGS | 378 gene rows, local 1D-y patch function-level equivalence PASS |
| **통계적 발견** | 없음 | 양쪽 모두 Bonferroni significant gene 0 |
| **방법 간 concordance** | 제한적 | shared 372 genes, Spearman 0.332, nominal overlap 6 |
| **한국인 ancestry-transfer 가설** | 미입증 | chr22-only, test/representation 차이, corrected signal 없음 |

이 프로젝트의 가장 큰 성과는 유의 gene을 발견한 것이 아니라, array-imputed rare-variant 분석에서 잘못된 결과가 만들어질 수 있는 지점을 실제로 찾아내고, 중단·수정·재검증하는 end-to-end 연구 계약을 구축한 것이다.

# 1. 최종 연구 질문과 chr22 프로젝트의 역할

## 1.1 최종 연구 질문

최종 목표는 DeepRVAT을 처음부터 재학습하거나 새로운 신경망을 개발하는 것이 아니다. 핵심 질문은 UK Biobank/EUR 중심으로 학습된 pretrained DeepRVAT/ML-RVAT 모델을 한국인 또는 East Asian 데이터에 적용할 때, 전체 retraining 없이 cohort-specific AF/MAF/MAC·carrier information과 같은 input-level annotation을 조정할 수 있는지, 그리고 그 조정이 결과의 calibration과 biological recovery를 개선하는지 판단하는 것이다.

이 질문은 다음 세 층으로 나뉜다.

27. 기술 가능성: array-imputed VCF를 DeepRVAT이 요구하는 HDF5/Parquet 입력으로 변환하고 association까지 끝낼 수 있는가.

28. 비교 가능성: 같은 sample, phenotype, covariate, variant universe, gene assignment와 baseline mask에서 SAIGE-GENE+와 비교할 수 있는가.

29. 전이 가능성: EUR 중심 pretrained representation이 한국인에서 얼마나 유지되며, KOR-specific frequency adjustment가 성능을 회복하는가.

## 1.2 chr22가 답하려던 질문

chr22는 생물학적 discovery chromosome이 아니라 technical canary였다. chr22 PASS가 의미하는 것은 pipeline의 입력 계약, build, annotation, sample/variant alignment, output validity를 확인했다는 것이며, DeepRVAT 우월성이나 한국인 일반화를 입증했다는 뜻이 아니다.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>왜 지금 chr22부터 했는가</strong></p>
<p>전 염색체를 먼저 실행하면 잘린 variant ID, 잘못된 genome build, 낮은 GP call, 빈 SAIGE output 같은 오류가 수일·수주의 계산 뒤에 발견된다. chr22에서 먼저 전체 흐름을 완주함으로써 재작업 비용과 false negative 해석 위험을 줄였다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## 1.3 비교 대상의 정확한 의미

SAIGE-GENE+는 ground truth가 아니다. fixed-rule mask와 burden/SKAT 계열 검정을 사용하는 baseline이고, DeepRVAT는 pretrained annotation representation을 이용한 learned burden 접근이다. 따라서 concordance가 낮다고 해서 어느 한쪽이 틀렸다고 단정할 수 없다.

# 2. 전체 작업의 시간순 지도

``` text
Phase 0 Array-imputed 데이터의 사전 타당성 검토
↓
Phase 1 보안 경계·fairness contract·Snakemake gate 설계
↓
Phase 2 phenotype·ID map·covariate·sample freeze
↓
Phase 3 초기 GT-only smoke BCF와 narrow chr22 liftover canary
↓
Phase 4 독립 검수: MAF 계약·hard-call confidence·annotation compatibility STOP-SHIP
↓
Phase 5 GT/DS/GP audit → GP90 primary, GP95 strict sensitivity, RAW_GT diagnostic
↓
Phase 6 source MAF prefilter 제거 → R2-only broad universe 재구축
↓
Phase 7 GRCh38 liftover·cohort GP90 AF/MAF·annotation resource 준비
↓
Phase 8 annotation 실패/HOLD → AF·feature·ID·chrom 문제 복구
↓
Phase 9 common gene mask → SAIGE Step1/Step2 → marker prefix 오류 수정
↓
Phase 10 DeepRVAT grouped sparse input·config·1D-y patch → association 완료
↓
Phase 11 sample/variant/annotation/result integrity audit
↓
Phase 12 shared 372 genes 결과 비교와 제한적 해석
```

| **시기** | **당시 상태** | **새로 발견한 문제** | **그 결과 바뀐 결정** |
|----|----|----|----|
| 초기 타당성 | Array도 schema 변환 가능성 있음 | DeepRVAT native dosage 경로 미확인 | hard-call 중심 기술 pilot 설계 |
| 초기 계획 | R2≥0.8, MAF\<0.01 primary | pretrained canonical MAF 계약과 불일치 | MAF\<0.001 validity branch를 중심으로 복원 |
| 독립 검수 | 공정 비교 계약은 강함 | R2·call rate만으로 carrier 확정 불가 | GP posterior threshold 필수 |
| narrow canary | 57,045→54,164 liftover PASS | source MAF prefilter가 universe를 잘라냄 | R2-only broad universe 재구축 |
| annotation 1차 | 일부 pipeline 진행 | AF/MAF source, PrimateAI/AlphaMissense, ID/chrom 문제 | association HOLD 후 복구 |
| SAIGE 1차 | exit 0 | set output 0 byte | marker prefix 일치 후 재실행 |
| DeepRVAT 1차 | runtime 오류 | 1D phenotype shape 및 config 문제 | local patch와 config 조정 후 재개 |
| 최종 감사 | 양쪽 output 존재 | singleAssoc 불일치, provenance 일부 약점 | gene-level pilot로만 해석 |

# 3. Phase 0: array-imputed 데이터를 DeepRVAT에 넣을 수 있는가

## 3.1 시작점의 근본적 불확실성

DeepRVAT의 공식 개발·검증 맥락은 UK Biobank WES rare-variant analysis였다. 보유 데이터는 KCHIP 기반 array genotype을 phasing하고 Minimac4로 imputation한 자료였다. 따라서 파일 확장자를 맞추는 문제가 아니라, 희귀 기능성 변이와 carrier uncertainty를 DeepRVAT 입력 계약에 맞게 표현할 수 있는지가 첫 blocker였다.

## 3.2 DeepRVAT 최종 입력 구조를 확인한 이유

| **입력** | **형식** | **역할** | **array 적용에서의 질문** |
|----|----|----|----|
| genotypes.h5 | HDF5 | sample별 sparse non-reference genotype | DS/GP 실수 정보를 보존할 수 있는가 |
| variants.parquet | Parquet | variant identity와 metadata | array variant key를 안정적으로 매핑할 수 있는가 |
| annotations.parquet | Parquet | MAF와 functional annotation | imputed variant에도 required feature를 붙일 수 있는가 |
| phenotypes.parquet | Parquet | phenotype/covariates | KNIH ID와 sample order를 맞출 수 있는가 |
| protein_coding_genes.parquet | Parquet | gene ID mapping | GRCh38 gene definition과 맞는가 |

공식 HDF5 구조는 `samples`, `variant_matrix`, `genotype_matrix`를 가지며 genotype은 non-reference ALT count 1 또는 2, padding은 -1인 sparse hard-call representation에 가깝다. 따라서 array라는 출발점 자체가 차단 사유는 아니지만, imputed DS/GP를 native하게 그대로 보존하는 공식 경로는 확인되지 않았다.

## 3.3 SAIGE와 DeepRVAT의 적용 가능성 판정

| **질문** | **당시 판정** | **현재 chr22 후 업데이트** |
|----|----|----|
| Array로 SAIGE single-variant 가능? | Confirmed | 가능 |
| Array로 SAIGE gene test 가능? | 기술적으로 가능, annotation/mask 필요 | 372 gene result 생성 |
| Array-imputed VCF→DeepRVAT schema 가능? | Likely | 실제 HDF5/Parquet 및 378 gene result 생성 |
| DS/GP를 DeepRVAT native 사용? | Unresolved / likely not native | 현재 구현은 GP90 hard-call 사용 |
| Array가 WES와 동등한 rare-variant 정보 제공? | 아님 | 여전히 아님 |
| Robust discovery 가능? | 탐색적으로만 가능 | chr22 corrected signal 0; 미검증 |

> **VERIFIED**
>
> chr22 완료 후 기술 가능성은 ‘Likely’에서 ‘실제 KNIH chr22에서 end-to-end 실행됨’으로 승격됐다.

> **UNRESOLVED**
>
> WES 대비 rare functional variant 회수 손실, population-specific variant 누락, native dosage 활용 가능성, genome-wide calibration은 해결되지 않았다.

# 4. 보안·재현성·운영 구조 설계

## 4.1 왜 분석 코드보다 운영 경계를 먼저 만들었는가

개인별 genotype·dosage·phenotype·ID map을 외부 AI가 직접 볼 수 없는 조건에서, 서버 Codex가 workflow를 작성·실행·복구하려면 데이터 내용과 운영 metadata를 분리해야 했다. 이를 control plane과 data plane으로 정의했다.

| **구분** | **허용 예** | **금지 예** |
|----|----|----|
| Control plane | 경로, 명령, config, tool version, 파일 크기, index, checksum, 집계 count, exit code | 개인 값이 포함되지 않은 안전한 운영 정보 |
| Data plane | 서버 내부 파일로만 처리 | sample ID 목록, genotype/DS/GP row, phenotype row, carrier list, ID map row |
| Restricted aggregate | small-cell suppression 후 gene-level summary | unsuppressed very-low-MAC 결과와 carrier 구조 |

## 4.2 구현 원칙

- `umask 077`, directory 0700, file 0600 등 restrictive permission.

- 원본 입력 불변, overwrite 금지, atomic staging 후 rename.

- 샘플 ID와 row 값을 stdout·chat·일반 log에 출력하지 않음.

- sample order, phenotype, covariate, variant universe, mask를 hash/contract로 비교.

- 미확인 config key나 command option을 추측하지 않고 BLOCKED gate로 남김.

- 실제 association 전에 synthetic unit/integration test, dry-run, schema validator를 요구.

## 4.3 fairness contract

계획상 primary fair comparison은 동일 sample/order, 동일 TCHL_rint, 동일 explicit covariates, 동일 hard-call GT variant universe, 동일 canonical variant key, 동일 gene assignment와 baseline mask를 양쪽 방법에 공급하는 것이었다.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>최종 실행과 계획의 차이</strong></p>
<p>최종 성공 SAIGE 경로는 `tchl_primary.ds.D90_MAF001...`이며 `--vcfField=DS`를 사용했다. DeepRVAT은 GP90 hard-call을 사용했다. 따라서 최종 chr22 비교는 계획한 hard-call-vs-hard-call 순수 공정 비교가 아니라, GP90-derived mask 아래에서 SAIGE dosage와 DeepRVAT hard-call learned burden을 비교한 pilot이다. 이 차이는 최종 해석에서 반드시 명시해야 한다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# 5. 연구 설계의 초기안, 독립 검수, 최종 수정

## 5.1 초기 설계

- Primary phenotype: TCHL_rint; sensitivity: TCHL_raw.

- Core covariates: age, age², sex, PC1–PC10; 기관·조사연도는 sensitivity.

- R2≥0.8 후 cohort GT-derived MAF\<0.01을 primary, MAF\<0.001을 sensitivity로 계획.

- 동일 hard-call GT를 DeepRVAT과 SAIGE에 공급하고 SAIGE DS를 별도 sensitivity로 계획.

- 초기 technical canary는 deterministic 5,000명과 최대 10 gene–mask unit.

## 5.2 독립 검수의 MAJOR REVISION

독립 검수는 workflow 구조와 보안 설계는 높게 평가했지만, 과학적 해석 전 STOP-SHIP 문제를 제기했다.

| **STOP-SHIP 문제** | **왜 위험했는가** | **요구된 수정** |
|----|----|----|
| MAF 계약 | pretrained DeepRVAT의 canonical rare 범위는 MAF\<0.001인데 MAF\<0.01을 primary로 사용 | MAF\<0.001 validity analysis 복원, MAF\<0.01은 exploratory |
| Imputed hard-call 신뢰도 | R2와 call rate는 개별 rare carrier posterior를 보장하지 않음 | GP/max posterior threshold, 미달 call missing, AF/MAF 재계산 |
| Annotation/model 호환성 | checkpoint·feature order·build·gene IDs 미확정 | pinned model/config와 full-feature coverage gate |
| 공통 endpoint | DeepRVAT burden과 SAIGE burden/SKAT/omnibus가 1:1 아님 | 결과 전 endpoint와 denominator 고정 |
| SAIGE Step1 | categorical variance ratio·MAC marker sufficiency·GRM/LOCO 미확정 | 버전별 Step1/2 계약 검증 |
| RINT 이중 적용 | 외부 TCHL_rint에 SAIGE invNormalize를 다시 적용할 위험 | SAIGE invNormalize=FALSE 명시 |

## 5.3 최종적으로 바뀐 핵심 결정

| **항목** | **초기** | **최종/실행** |
|----|----|----|
| Rare threshold | MAF\<0.01 primary | D90_MAF001 canonical branch를 최종 chr22 비교에 사용; MAF01 branch는 exploratory |
| Genotype confidence | raw GT hard-call | GP90 primary; GP95 strict sensitivity; RAW_GT diagnostic-only |
| Canary sample | N=5,000 계획 | 최종 association은 phenotype complete-case 58,639명 사용 |
| Variant universe | source INFO/MAF 선필터 | R2-only broad universe 후 cohort GP90 AF/MAF |
| Annotation | 기존/부분 feature | 34 required features full validation PASS |
| SAIGE representation | hard-call 계획 | 최종 성공 run은 DS |
| DeepRVAT test | pretrained association | `do_scoretest=false` burden/regression result |

> **INFERENCE**
>
> 5,000명에서 58,639명으로 확대한 상세 승인 로그는 현재 첨부 자료에 완전히 남아 있지 않다. 다만 최종 산출 zarr와 phenotype parquet이 58,639명을 사용한 것은 검증됐다.


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 1/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [다음글: phenotype, 표본 동결, GT·DS·GP 및 GP90 결정](/posts/knih-deeprvat-saige-chr22-02-phenotype-gp90/)
</nav>
