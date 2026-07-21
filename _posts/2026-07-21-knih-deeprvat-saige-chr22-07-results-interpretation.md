---
layout: post
title: "7/8 최종 결과, 해석, 한계와 다음 단계"
date: 2026-07-21 13:07:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 7/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: DeepRVAT 실행과 무결성 감사](/posts/knih-deeprvat-saige-chr22-06-deeprvat/) · [다음글: 부록: 경로, 결정 로그, Evidence Log](/posts/knih-deeprvat-saige-chr22-08-appendices/)
</nav>

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


<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 7/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: DeepRVAT 실행과 무결성 감사](/posts/knih-deeprvat-saige-chr22-06-deeprvat/) · [다음글: 부록: 경로, 결정 로그, Evidence Log](/posts/knih-deeprvat-saige-chr22-08-appendices/)
</nav>
