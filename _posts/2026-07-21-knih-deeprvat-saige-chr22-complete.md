---
layout: post
title: "KNIH array-imputed genotype 기반 DeepRVAT–SAIGE-GENE+ chr22 프로젝트 전체 기록"
date: 2026-07-21
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

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

# 16. 최종 결과 harmonization과 통계 비교

## 16.1 gene ID mapping

SAIGE는 Ensembl Region ID, DeepRVAT는 내부 numeric gene ID를 사용했다. `protein_coding_genes.parquet`으로 numeric ID를 Ensembl ID와 gene name에 매핑했다.

| **항목**                     | **수** |
|------------------------------|--------|
| SAIGE tested genes           | 372    |
| DeepRVAT tested genes        | 378    |
| Shared comparable genes      | 372    |
| DeepRVAT-only testable genes | 6      |

## 16.2 multiple-testing 결과

| **Method/test** | **Threshold**        | **Significant genes** |
|-----------------|----------------------|-----------------------|
| SAIGE omnibus   | 0.05/372 = 0.0001344 | 0                     |
| SAIGE burden    | same family report   | 0                     |
| SAIGE SKAT      | same family report   | 0                     |
| DeepRVAT        | 0.05/378 = 0.0001323 | 0                     |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>가장 강한 통계적 결론</strong></p>
<p>chr22에서 Bonferroni correction을 통과한 gene-level association은 양쪽 방법 모두 없었다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

## 16.3 nominal signal과 concordance

| **지표**                      | **값**          |
|-------------------------------|-----------------|
| SAIGE omnibus nominal p\<0.05 | 27              |
| SAIGE burden nominal p\<0.05  | 27              |
| SAIGE SKAT nominal p\<0.05    | 27              |
| DeepRVAT nominal p\<0.05      | 26              |
| Both nominal p\<0.05          | 6               |
| Spearman corr of -log10(p)    | 0.332           |
| Pearson corr of -log10(p)     | 0.362           |
| Effect sign agreement         | 247/372 = 0.664 |
| Top 10 overlap                | 1               |
| Top 20 overlap                | 3               |
| Top 50 overlap                | 16              |

Spearman 0.332는 완전한 무관계는 아니지만 강한 ranking agreement도 아니다. 그러나 SAIGE는 DS+omnibus/SKAT 구조이고 DeepRVAT는 GP90 hard-call learned burden이므로, 이 수치는 method-only concordance가 아니라 method+representation+test-alternative의 결합 차이다.

# 17. 주요 후보와 방법론적 해석

## 17.1 양쪽 모두 nominal인 6 genes

| **Gene** | **SAIGE p** | **DeepRVAT p** | **SAIGE rank** | **DeepRVAT rank** | **방향** | **해석** |
|----|----|----|----|----|----|----|
| GGA1 | 0.001369 | 0.001659 | 1 | 3 | 일치 | 가장 강한 shared nominal; rare variants 2개 |
| DUSP18 | 0.006829 | 0.02552 | 6 | 13 | 일치 | 양쪽 nominal, 방향 일치 |
| FBLN1 | 0.02085 | 0.0009553 | 15 | 1 | 일치 | DeepRVAT 1위, SAIGE nominal support |
| NCF4 | 0.02728 | 0.04528 | 18 | 25 | 일치 | 낮은 MAC/variant count에 민감 가능 |
| ARVCF | 0.03626 | 0.04612 | 22 | 26 | 일치 | 경계 nominal concordance |
| DENND6B | 0.0498 | 0.02394 | 27 | 12 | 일치 | 약한 overlap candidate |

## 17.2 SAIGE-only pattern

EFCAB6와 MRTFA는 SAIGE burden은 약하지만 SKAT가 강했다. 이는 gene 안 variant effect direction이 섞이거나 일부 variant만 기여하는 상황과 양립한다.

| **Gene** | **SAIGE omnibus** | **Burden p** | **SKAT p** | **DeepRVAT p** | **핵심 패턴** |
|----|----|----|----|----|----|
| EFCAB6 | 0.002093 | 0.487 | 0.0009572 | 0.9839 | SKAT-driven |
| MRTFA | 0.005972 | 0.9524 | 0.003027 | 0.2101 | SKAT-driven |
| SGSM3 | 0.006128 | 0.04515 | 0.004319 | 0.377 | SKAT/burden mixed |
| GCAT | 0.01243 | 0.006931 | 0.02672 | 0.4364 | burden signal, DeepRVAT 약함 |

이 불일치는 ancestry failure가 아니라 SKAT의 variance-component alternative와 DeepRVAT learned burden의 차이로도 설명될 수 있다.

## 17.3 DeepRVAT-only pattern

| **Gene** | **DeepRVAT p** | **SAIGE omnibus p** | **해석 경계** |
|----|----|----|----|
| PPP6R2 | 0.001512 | 0.08294 | pretrained weighting이 강조한 후보 |
| THOC5 | 0.002116 | 0.0977 | SAIGE support 경계 밖 |
| ATXN10 | 0.005665 | 0.3143 | method-specific exploratory |
| OSM | 0.01006 | 0.2614 | 생물학적 plausibility와 association 증거 분리 필요 |
| PMM1 | 0.01329 | 0.05846 | SAIGE burden은 nominal이나 omnibus는 경계 밖 |
| CYB5R3 | 0.04258 | 0.3418 | 약한 DeepRVAT-only 후보 |

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>후보 gene의 올바른 명칭</strong></p>
<p>모두 discovery gene이나 causal gene이 아니라 ‘chr22 shared/method-specific nominal follow-up candidate’다. corrected significance가 없고, carrier-level 확인과 독립 replication이 없다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>

# 18. 결과 무결성 감사와 잔여 위험

## 18.1 대형 pipeline 오류 가능성을 낮춘 근거

- SAIGE가 header-only/0-byte였던 실제 오류를 찾아 수정했고, 수정 후 372 rows 생성.

- DeepRVAT all_results 378 rows, p-value/beta numeric, workflow 48/48, exit 0.

- variant–annotation ID 상호 누락 0, duplicate ID–gene 0.

- xy와 burden sample 58,639명 및 순서 동일.

- p-value가 전부 NA·0·1로 붕괴하지 않음.

- Bonferroni significant 0이 all_results, significant.parquet, minimum corrected p와 일치.

## 18.2 갱신된 위험 매트릭스

| **위험** | **영향** | **현재 검증** | **최종 판정** |
|----|----|----|----|
| Wrong chr/build | 매우 큼 | CHROM=22, GRCh37→38, REF mismatch 0 | 낮음 |
| Source MAF truncation | 큼 | R2-only broad universe로 재구축 | 해결 |
| Raw imputed carrier error | 큼 | GP audit, GP90 missing policy | 상당히 낮아짐 |
| Annotation ID/chrom mismatch | 큼 | canonical repair, ID universe 0 missing | 낮음 |
| Missing pretrained features | 큼 | 34 features missing_n=0 | 낮음 |
| SAIGE marker mismatch | 큼 | prefix fix 후 output/markerList 일치 | 해결 |
| SAIGE Step1 variance ratio/GRM | 큼 | 최종 output 존재하나 독립 계약 불완전 | 잔여 주요 위험 |
| SAIGE allele order beta | 중간~큼 | ref-first 설정만 확인 | 잔여 위험 |
| DeepRVAT sample alignment | 매우 큼 | xy/burden order PASS | 낮음 |
| DeepRVAT 1D-y patch | 큼 | function-level equivalence PASS | 낮아짐 |
| Method fairness | 큼 | SAIGE DS vs DeepRVAT GP90 GT | 해결되지 않음; 해석 제한 |
| singleAssoc reconciliation | 중간 | set-level은 PASS, variant-level 불일치 | variant 해석 위험 |
| Provenance done marker | 중간 | ASSOC_INPUT_PREP.done 없음 | 재현성 약점 |
| chr22-only | 매우 큼 | 해결 불가 | 핵심 과학적 한계 |

## 18.3 결과를 ‘사용 불가’로 보지 않는 이유

최종 결과는 주요 pipeline 오류가 검출·수정·감사된 technical canary다. 다만 representation-controlled fair comparison, genome-wide calibration, external replication이 없기 때문에 scientific performance benchmark로 승격할 수는 없다.

# 19. 무엇을 말할 수 있고 무엇을 말하면 안 되는가

| **가능한 표현** | **금지하거나 과도한 표현** |
|----|----|
| KNIH array-imputed data에서 DeepRVAT chr22 association까지 기술적으로 실행했다. | Array가 WES와 동등하다. |
| GP90 posterior gate로 불확실 hard-call을 missing 처리했다. | R2≥0.8이면 rare carrier가 확정된다. |
| 양쪽 모두 corrected significant gene은 없었다. | 유의한 유전자를 발견했다. |
| shared 372 genes에서 concordance가 제한적이었다. | DeepRVAT가 한국인에서 실패했다. |
| GGA1, FBLN1, DUSP18은 nominal follow-up 후보다. | 이 gene이 TCHL causal gene이다. |
| 관찰된 discordance는 ancestry-transfer 가설과 양립한다. | ancestry-transfer failure가 입증됐다. |
| 최종 비교는 SAIGE DS와 DeepRVAT GP90 hard-call을 포함한다. | 완전히 동일 genotype representation의 순수 방법 비교다. |
| chr22는 technical pilot이다. | chr22 결과로 genome-wide 방법 우열을 결론냈다. |

# 20. 발표용 완성 서사

## 20.1 15분 발표 구조

| **슬라이드** | **제목** | **핵심 메시지** |
|----|----|----|
| 1 | 연구 질문 | EUR pretrained DeepRVAT을 KOR array-imputed data에 재학습 없이 적용 가능한가 |
| 2 | 왜 array feasibility부터 봤나 | DeepRVAT native dosage와 rare variant coverage가 불확실 |
| 3 | 사전 판정 | 기술적으로 조건부 가능, robust discovery는 WES/WGS가 우위 |
| 4 | 보안·fairness contract | same sample/phenotype/covariate/mask와 control-data boundary |
| 5 | 독립 검수와 설계 수정 | MAF\<0.001 canonical, GP confidence 필수 |
| 6 | GP 정책 | RAW_GT diagnostic, GP90 primary, GP95 strict sensitivity, DS SAIGE |
| 7 | variant universe | narrow 54,164에서 broad 123,064로 재구축 |
| 8 | phenotype/sample | TCHL_rint, 58,639 complete-case |
| 9 | liftover/cohort AF | REF mismatch 0, cohort GP90 AF/MAF |
| 10 | annotation recovery | ID/chrom/feature 문제 복구, 34 features PASS |
| 11 | SAIGE 오류 | exit 0·0 byte를 marker prefix fix로 해결 |
| 12 | DeepRVAT audit | sample order, ID universe, 1D-y patch PASS |
| 13 | 결과 | 372 shared genes, corrected significant 0 |
| 14 | concordance | rho 0.332, nominal overlap 6 |
| 15 | 결론/다음 단계 | 기술 가능성 실증, ancestry 성능 미입증, genome-wide 필요 |

## 20.2 발표에서 그대로 읽을 수 있는 통합 대본

> 이 연구는 처음부터 array-imputed 데이터를 DeepRVAT에 사용할 수 있다고 가정하고 시작하지 않았습니다. DeepRVAT의 공식 개발 맥락은 UK Biobank WES 희귀변이 분석이었고, 저희 데이터는 KCHIP array를 phasing한 뒤 Minimac4로 imputation한 자료였습니다. 따라서 첫 질문은 유의한 유전자를 찾는 것이 아니라, 이 데이터가 DeepRVAT의 sparse hard-call HDF5와 annotation parquet 계약으로 변환될 수 있는지였습니다.

> 공식 입력 구조를 확인한 결과, array라는 출발점 자체가 코드 수준의 금지 조건은 아니었습니다. 하지만 DeepRVAT의 genotype HDF5는 ALT count 1 또는 2를 저장하는 sparse hard-call 구조에 가깝고, imputed DS나 GP를 native하게 그대로 보존하는 경로는 확인되지 않았습니다. 그래서 초기 판정은 기술적으로 조건부 가능하지만, 과학적으로는 탐색적이라는 것이었습니다.

> 그다음 동일한 한국인 표본과 phenotype, covariate, variant universe와 gene mask를 두 방법에 공급하는 fairness contract를 설계했습니다. 개별 genotype과 phenotype을 외부 AI가 보지 않도록 control plane과 data plane을 나누고, 경로·명령·checksum·aggregate QC만 운영 정보로 공유했습니다. Phenotype은 CT1_TCHL에서 특수 결측코드를 제거하고 TCHL_raw와 TCHL_rint를 만들었으며, 최종 complete-case 58,639명을 동결했습니다.

> 초기 계획은 R2 0.8 이상, MAF 0.01 미만을 primary로 두는 것이었지만 독립 검수에서 두 가지 핵심 문제가 제기됐습니다. 첫째, pretrained DeepRVAT의 canonical rare-variant 범위는 MAF 0.001 미만이라는 점입니다. 둘째, imputed best-guess GT는 call rate가 높아도 개별 rare carrier가 정확하다는 뜻이 아니라는 점입니다. 이에 MAF 0.001 branch를 validity 중심으로 복원하고, GT·DS·GP를 직접 비교해 posterior threshold를 결정했습니다.

> narrow chr22 audit에서 GP90 미달 genotype cell은 missing으로 바뀌었고, low-confidence carrier cell이 164만 개 이상 확인됐습니다. 이에 raw GT는 diagnostic-only, GP90을 primary hard-call, GP95를 strict sensitivity, DS는 SAIGE의 uncertainty-aware branch로 고정했습니다. R2는 variant-level quality, GP90은 sample–variant cell-level confidence로 서로 다른 역할을 합니다.

> 초기 source-MAF filtered canary는 57,045개 중 54,164개가 GRCh38로 옮겨졌지만, source MAF prefilter가 한국인 cohort frequency universe를 미리 잘라낸다는 문제가 남았습니다. 그래서 source INFO/MAF cutoff를 제거한 R2-only broad universe를 다시 만들었습니다. 130,251개 중 123,064개가 GRCh38로 mapping됐고, target REF mismatch와 duplicate canonical key는 모두 0이었습니다. 이 123,064개에 대해 GP90 cohort AF와 MAF를 다시 계산했습니다.

> Annotation 단계에서는 required feature 누락, cohort AF와 external gnomAD AF의 혼동 가능성, variant ID truncation과 chr22/22 표기 불일치가 발견돼 association을 HOLD했습니다. CADD, SpliceAI, AlphaMissense, PrimateAI, AbSplice, DeepRiPe 등 resource와 pipeline을 복구하고 canonical key로 ID를 고친 뒤, 160,656 annotation rows에서 duplicate ID-gene 0, required pretrained feature 34개 누락 0을 확인했습니다.

> SAIGE Step2의 첫 실행은 exit code 0이었지만 결과가 0 byte였습니다. 원인은 group marker가 chr22로 시작하고 VCF chromosome은 22였기 때문입니다. prefix를 22로 고친 뒤 372개의 gene-level result와 일치하는 markerList가 생성됐습니다. 이 경험은 exit code 0이 통계 분석 성공을 보장하지 않는다는 것을 보여줍니다.

> DeepRVAT에서는 grouped sparse input을 만들고 chromosome을 integer 22로 지정했으며, do_scoretest false, 38 regression chunks, num_workers 0으로 조정했습니다. 1차원 phenotype vector를 2차원으로 확장하는 local patch가 필요했지만 synthetic smoke test에서 기존 2D 입력과 beta와 p-value가 완전히 같았습니다. 최종 association 내부에서 phenotype과 burden sample은 모두 58,639명이고 순서도 동일했으며, variant와 annotation ID의 상호 누락은 0이었습니다. DeepRVAT은 378개 gene result를 생성했습니다.

> 최종적으로 SAIGE 372개, DeepRVAT 378개, 공통 비교 가능 gene은 372개였습니다. 양쪽 모두 Bonferroni significant gene은 0개였습니다. Nominal p 0.05 미만은 SAIGE 27개, DeepRVAT 26개였고 공통은 GGA1, DUSP18, FBLN1, NCF4, ARVCF, DENND6B의 6개였습니다. minus log10 p의 Spearman correlation은 0.332이고 top 10 overlap은 GGA1 한 개였습니다.

> 그러나 이 결과를 DeepRVAT의 한국인 성능 저하라고 결론내릴 수는 없습니다. 최종 SAIGE는 DS dosage와 omnibus/SKAT 구조를 사용했고 DeepRVAT은 GP90 hard-call learned burden을 사용했으므로 test와 genotype representation이 모두 다릅니다. 또한 corrected significant signal이 없고 chr22 하나뿐입니다. 따라서 현재 결론은 KNIH array-imputed data에서 DeepRVAT의 기술 실행 가능성을 실증했고, chr22에서 제한적인 method-level concordance를 관찰했다는 것입니다. Ancestry transfer와 KOR-specific input annotation adjustment의 효과를 말하려면 chr1–21 전체와 EUR/reference AF 대비 KOR AF의 사전 정의된 비교가 필요합니다.

# 21. 다음 단계와 연구 질문의 재정의

## 21.1 기술 production 전 필수 gate

30. SAIGE Step1 categorical variance-ratio, MAC bins, GRM/sparse-GRM, LOCO, Step1–Step2 sample/phenotype contract를 재승인한다.

31. Primary hard-call-vs-hard-call comparison을 별도로 실행해 genotype representation 효과를 분리한다.

32. SAIGE DS branch는 같은 canonical site list와 mask에서 representation-controlled sensitivity로 유지한다.

33. GP90·GP95 branch의 chromosome별 callable cells, AC, testable genes, cMAC distribution을 자동 기록한다.

34. Final association directory마다 input prep done marker, config checksum, symlink target manifest를 생성한다.

35. singleAssoc와 markerList variant reconciliation을 완료한 뒤에만 variant-level 해석을 허용한다.

## 21.2 genome-wide scientific analysis

36. chr1 production resource test로 runtime, memory, scratch, I/O를 측정한다.

37. chr1–21 전체에서 chromosome별 tested/shared genes, p-value calibration, top-k overlap, rank correlation, sign agreement를 반복한다.

38. SAIGE burden vs DeepRVAT learned burden, SAIGE SKAT vs DeepRVAT, SAIGE omnibus vs DeepRVAT를 분리한다.

39. 사전 고정한 lipid/cholesterol positive-control gene set의 rank/enrichment를 matched-gene null과 비교한다.

40. MAF\<0.001 canonical branch와 MAF\<0.01 exploratory branch를 별도 family로 유지한다.

41. TCHL_raw, GP95, covariate sensitivity를 결과를 보기 전에 고정한다.

## 21.3 중심 연구 질문을 직접 검정하는 설계

현재 chr22 run은 KOR cohort AF를 넣은 한 조건만 수행했다. Input-level adjustment 효과를 직접 말하려면 동일 genotype·sample·phenotype·checkpoint를 고정하고 frequency-related input만 바꾸는 counterfactual comparison이 필요하다.

| **조건** | **Frequency/annotation** | **목적** |
|----|----|----|
| A. Pretrained reference-like | 공식 pretrained config가 기대하는 reference feature | 기준 |
| B. KOR cohort AF | GP90 cohort AF/MAF/MAC | 한국인 직접 조정 |
| C. EAS external AF | 공식적으로 확보한 EAS frequency | 외부 조상집단 reference |
| D. Shrinkage | KOR direct와 external EAS/EUR의 사전 고정 shrinkage | small-count 안정화 |

모든 조건에서 checkpoint 재학습 없이 gene score와 association rank가 어떻게 변하는지 평가해야 ‘input-level annotation adjustment가 가능한가’에 직접 답할 수 있다.

# 부록 A. 핵심 수치 타임라인

| **단계** | **표본/variant/gene 수** | **결론** |
|----|----|----|
| 원 genotype cohort | 87,430 samples | imputed VCF 전체 |
| Final phenotype complete-case | 58,639 samples | TCHL_rint association cohort |
| 초기 smoke BCF | 34,591 variants | source MAF\<0.001, GT-only; primary 아님 |
| narrow source-filtered canary | 57,045 variants | 초기 liftover/representation test |
| narrow GRCh38 | 54,164 variants | 2,881 rejected, REF mismatch 0 |
| R2-only broad source | 130,251 variants | source MAF cutoff 제거 |
| R2-only broad GRCh38 | 123,064 variants | 7,187 rejected |
| Final annotation | 160,656 rows | 85,205 gene assigned, 34 features |
| D90_MAF001 mask | 4,296 variants / 376 genes | primary final mask |
| SAIGE set result | 372 genes | DS, marker prefix corrected |
| DeepRVAT result | 378 genes | GP90 hard-call learned burden |
| Shared comparison | 372 genes | Bonferroni significant 0/0 |

# 부록 B. 경로·스크립트·산출물 manifest

| **항목** | **경로** |
|----|----|
| Raw chr22 VCF | `<KNIH_DATA_ROOT>/01.raw_KNIH3/KCHIPcohort_n6.chr22.tsim2nd.vcf.gz` |
| Project root | `<PROJECT_ROOT>/0715deeprvat/knih_deeprvat_saige_v3_20260715_212232` |
| Broad GRCh38 VCF | `work/grch38_liftover/r2_only_broad/chr22.r2only.r2_0_8/chr22.r2only.r2_0_8.grch38.norm.vcf.gz` |
| Broad GRCh38 BCF | `work/grch38_liftover/r2_only_broad_bcf/chr22.r2only.r2_0_8/chr22.r2only.r2_0_8.grch38.norm.bcf` |
| Cohort AF table | `reports/chr22.r2only.r2_0_8.cohort_af_gp90.COHORT_AF_GP90.tsv` |
| Cohort AF summary | `reports/chr22.r2only.r2_0_8.cohort_af_gp90.COHORT_AF_GP90_SUMMARY.tsv` |
| Final annotation | `work/deeprvat_grch38/broad_chr22_r2only_20260719_2212/annotations/annotations.chr22_broad_r2only_gp90_absplice_idfix_analysis2_20260720.parquet` |
| Common mask root | `work/common_gene_mask_v2_20260720_233309` |
| SAIGE group | `work/common_gene_mask_v2_20260720_233309/saige_group_files/D90_MAF001.saige_vcf_chrom22.group.txt` |
| SAIGE result | `work/saige_gene/grch38_chr22/step2/tchl_primary.ds.D90_MAF001.chrom22idfix_20260721` |
| DeepRVAT assoc root | `work/deeprvat_grch38/assoc_chr22_safe_20260721_grouped40_assoc_chrfix_20260721_054524` |
| DeepRVAT burden | `TCHL_rint/deeprvat/average_regression_results/burden_associations.parquet` |
| DeepRVAT all results | `TCHL_rint/deeprvat/eval/all_results.parquet` |
| DeepRVAT significant | `TCHL_rint/deeprvat/eval/significant.parquet` |
| Gene mapping | `work/deeprvat_grch38/reference/protein_coding_genes.parquet` |

## 주요 스크립트

- `build_r2_only_broad_liftover_input.sh`

- `run_cohort_af_gp90_from_bcf.sh`

- `compute_cohort_af_from_bcf_stream.py`

- `repair_annotation_ids_from_variant_keys.py`

- `normalize_annotation_chrom_for_variants.py`

- `postprocess_chr22_annotation_absplice_v2.py`

- `validate_final_annotation.py`

- `prepare_deeprvat_assoc_inputs_grouped_shards_20260721.sh`

- `prepare_deeprvat_assoc_chr_generic.sh`

# 부록 C. 설계 결정 로그

| **결정** | **선택** | **배제/대안** | **근거** |
|----|----|----|----|
| 데이터 유형 | array-imputed를 technical/method pilot로 사용 | WES와 동등하다고 간주하지 않음 | DeepRVAT schema 변환 가능, rare coverage 한계 |
| Primary phenotype | TCHL_rint | TCHL_raw는 sensitivity | 분포 안정화, 양쪽 동일 변환 |
| Site quality | R2≥0.8 | R2만으로 carrier 확정 금지 | site quality와 cell confidence 분리 |
| Hard-call confidence | GP90 | RAW_GT diagnostic, GP95 strict | low-confidence carrier 다수 |
| Rare threshold | MAF\<0.001 validity | MAF\<0.01 exploratory | pretrained canonical 범위 |
| Frequency source | KNIH GP90 cohort AF | source INFO/MAF를 final cutoff로 사용하지 않음 | 한국인 frozen universe |
| External frequency | gnomADg_AF 별도 | AF로 alias 금지 | feature 의미 보존 |
| Build | GRCh38 downstream | GRCh37 annotation 직접 사용 금지 | DeepRVAT resource alignment |
| Variant identity | CHROM:POS:REF:ALT canonical | raw VCF ID 또는 단순 prefix 추측 금지 | join integrity |
| SAIGE representation | 최종 DS run | hard-call fair branch는 향후 필요 | imputation uncertainty 보존 |
| DeepRVAT representation | GP90 ALT-count sparse hard-call | DS native 미확인 | 공식 HDF5 구조 |
| DeepRVAT association | do_scoretest=false regression | scoretest 결과로 부르지 않음 | final config |
| chr22 해석 | technical pilot | method superiority/biology 결론 금지 | 한 chromosome, signal 0 |

# 부록 D. Evidence Log

근거 수준: VERIFIED=자료/감사에서 직접 확인, EXECUTED=실제 산출물 완료, PLANNED=계획됐으나 실행 증거 불충분, CORRECTED=오류 발견 후 수정, UNRESOLVED=현재 자료로 확정 불가.

| **ID** | **근거 자료** | **지원하는 claim** | **상태** |
|----|----|----|----|
| E1 | Array 기반 SNP 데이터로 SAIGE 유전자검정과 DeepRVAT를 돌릴 수 있는가 | 사전 타당성, DeepRVAT HDF5/Parquet, native dosage 미확인 | VERIFIED |
| E2 | FINAL_KNIH_DEEPRVAT_SAIGE_PLAN_v2 | 초기 설계, fairness contract, phenotype/covariate, MAF 계획 | VERIFIED/PLANNED |
| E3 | KNIH DeepRVAT–SAIGE-GENE+ 독립 검수 보고서 v1 | MAF\<0.001, GP hard-call confidence, annotation·Step1 STOP-SHIP | VERIFIED |
| E4 | SNAKEMAKE_CODEX_HANDOFF / runbook / control-data boundary | 보안·gate·reproducibility 구조 | VERIFIED |
| E5 | prepare_tchl_phenotype.py와 tests | special missing, TCHL_raw/rint, ID merge, output contract | VERIFIED |
| E6 | DeepRVAT chr22 annotation 실패 원인 분석과 복구 지침 | HOLD, cohort AF, feature recovery, gnomAD 분리 | VERIFIED |
| E7 | 붙여넣은 마크다운(1): chr22 integrity audit | 최종 경로, liftover, AF, annotation, SAIGE/DeepRVAT audit | EXECUTED |
| E8 | 붙여넣은 마크다운(2): detailed hypothesis report | 최종 통계, top genes, concordance, interpretation | EXECUTED |
| E9 | 이전 서버 집계 기록 | GT/DS/GP narrow canary, GP90 policy와 low-confidence carrier counts | VERIFIED in project record; 원문 파일 미복원 |
| E10 | 최종 association 산출 metadata | xy/burden zarr alignment, HDF5/Parquet shapes | EXECUTED |

## 최종 확인된 것

- Array-imputed KNIH chr22 데이터는 GP90 hard-call과 full annotation을 거쳐 DeepRVAT association까지 실행 가능하다.

- Raw best-guess GT는 rare-carrier primary로 부적절하며 GP posterior gate가 필요하다.

- Source MAF 선필터를 제거하고 cohort GP90 AF/MAF를 계산하는 것이 필요했다.

- GRCh37→GRCh38 mapped 123,064개에서 target REF mismatch와 canonical duplicate는 0이었다.

- Final annotation은 34 required features와 ID universe gate를 통과했다.

- SAIGE 0-byte output의 실제 원인은 marker prefix mismatch였고 수정됐다.

- DeepRVAT sample/variant alignment와 1D-y patch는 추가 감사에서 위험이 크게 낮아졌다.

- 양쪽 corrected significant gene은 0이고 concordance는 제한적이었다.

## 아직 모르는 것

- GP90이 genome-wide에서 최적 threshold인지, GP95/DS와 결과가 얼마나 달라지는가.

- SAIGE hard-call-vs-DeepRVAT hard-call의 representation-controlled concordance.

- SAIGE Step1 variance-ratio/GRM/allele-order의 완전한 독립 재검증.

- EUR/reference AF 대비 KOR cohort AF input adjustment가 gene score와 association을 얼마나 변화시키는가.

- chr1–21에서도 chr22의 discordance가 반복되는가.

- WES/WGS truth set 대비 array-imputed rare variant 회수율과 false carrier rate.

- External lipid positive-control 및 독립 cohort replication.

<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr>
<th><p><strong>문서의 최종 사용법</strong></p>
<p>발표에서는 본문의 0–5절로 연구 배경과 설계 변경을 설명하고, 8–16절에서 실제 실행·오류·결과를 설명한다. 질문 대응에는 18–19절의 위험과 해석 경계를 사용한다. 서버 재현에는 부록 B–D를 사용한다.</p></th>
</tr>
</thead>
<tbody>
</tbody>
</table>
