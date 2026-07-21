---
layout: post
title: "8/8 부록: 경로, 결정 로그, Evidence Log"
date: 2026-07-21 13:08:00 +0900
categories: [Genetics, Rare-Variant, DeepRVAT, SAIGE]
tags: [DeepRVAT, SAIGE-GENE+, KNIH, array-imputation, rare-variant, GP90]
toc: true
---

{% include private_path_toggle.html %}

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 8/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 최종 결과, 해석, 한계와 다음 단계](/posts/knih-deeprvat-saige-chr22-07-results-interpretation/) · [다음글: 완전판](/posts/knih-deeprvat-saige-chr22-complete/)
</nav>

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

<nav class="series-navigation" aria-label="KNIH chr22 연재 이동">
**연재 8/8** · [완전판](/posts/knih-deeprvat-saige-chr22-complete/) · [앞글: 최종 결과, 해석, 한계와 다음 단계](/posts/knih-deeprvat-saige-chr22-07-results-interpretation/) · [다음글: 완전판](/posts/knih-deeprvat-saige-chr22-complete/)
</nav>
