---
title: "Splicing motif와 variant annotation"
date: 2026-06-29 18:30:00 +0900
categories: [Study, Genomics]
tags: [DeepRVAT, rare-variant, annotation, splicing, genomics]
description: "DeepRVAT annotation 문서를 읽다가, synonymous variant와 splicing motif를 variant weight 설계에서 어떻게 다뤄야 할지 정리한 노트."
math: true
---

DeepRVAT의 [annotation 문서](https://github.com/PMBio/deeprvat/blob/main/docs/annotations.md)를 읽다가 rare variant에 weight를 줄 때 무엇을 기준으로 삼아야 하는지 막혔다. 처음에는 `synonymous`, `missense`, `splice-disrupting`, `protein-truncating` 같은 label을 영향 크기의 순서처럼 읽고 있었다. 그런데 splicing 쪽을 들여다보면 이들을 한 줄에 세우기 어렵다.

아래는 그 지점을 풀어 보려고 쓴 노트다. 특히 `synonymous variant`가 왜 항상 "조용한 변이"로 끝나지 않는지, `splicing motif`를 중심으로 정리했다.

## 먼저 축을 나누기

variant consequence는 한 줄로 세워 놓는 순간 헷갈렸다. label마다 묻는 질문이 다르기 때문이다.

| 축 | 예시 | 보는 기준 |
| --- | --- | --- |
| Codon-level consequence | `synonymous`, `missense`, `nonsense` | codon 변화가 amino acid를 바꾸는가 |
| RNA-processing consequence | `splice-disrupting` | pre-mRNA 처리, 특히 splicing이 망가지는가 |
| Protein-level severe consequence | `protein-truncating` | 최종 protein이 짧아지거나 severe loss-of-function으로 이어지는가 |

여기서 내가 헷갈렸던 부분은 `splice-disrupting`과 `protein-truncating`이었다. 둘은 같은 층의 말이 아니다. `splice-disrupting`은 RNA 처리 과정에서 생긴 문제를 가리키고, `protein-truncating`은 그 결과로 protein이 짧아지거나 기능을 크게 잃을 가능성을 가리킨다. 어떤 splice-disrupting variant는 PTV처럼 작동할 수 있지만, 모든 splice-disrupting variant가 PTV인 것은 아니다.

## DNA에서 protein까지

유전정보의 흐름은 크게 이렇게 이어진다.

```text
DNA
  -> transcription
  -> pre-mRNA
  -> splicing
  -> mature mRNA
  -> translation
  -> protein
```

DNA와 pre-mRNA에는 exon과 intron이 함께 들어 있다.

```text
[Exon 1] --- (Intron 1) --- [Exon 2] --- (Intron 2) --- [Exon 3]
```

splicing이 일어나면 intron은 제거되고 exon끼리 이어진다.

```text
[Exon 1][Exon 2][Exon 3]
```

여기서 한 번 걸리는 부분이 있다. exon이 곧 protein-coding sequence는 아니다. exon은 mature RNA에 남는 구간을 뜻한다. 그 안에는 coding sequence뿐 아니라 UTR 같은 비번역 구간도 들어갈 수 있다.

## Splicing motif는 RNA 편집 좌표계다

splicing motif를 이름 목록으로만 외우면 금방 헷갈린다. 내가 잡은 핵심은 이렇다.

> splicing motif는 pre-mRNA에서 어디를 자르고, 어디를 남기고, 어디를 붙일지 정하는 신호다.

세포 입장에서는 긴 pre-mRNA를 두고 이런 문제를 풀어야 한다.

1. intron은 어디서 시작하는가?
2. intron은 어디서 끝나는가?
3. intron 제거 반응은 어디를 기준으로 진행되는가?
4. 어떤 exon 또는 splice site를 실제로 사용할 것인가?

이 질문에 맞춰 splicing signal을 네 층으로 나누면 훨씬 덜 헷갈린다.

| 층 | 신호 | 역할 |
| --- | --- | --- |
| 경계 신호 | `5' splice site`, `3' splice site` | intron의 시작과 끝을 알려준다 |
| 반응 신호 | `branch point` | intron 제거 반응의 내부 기준점이 된다 |
| 문맥 신호 | `polypyrimidine tract`, `PPT` | `3' splice site` 인식을 안정화한다 |
| 조절 신호 | `ESE`, `ESS`, `ISE`, `ISS` | exon 또는 splice site 사용 확률을 조절한다 |

## 경계 신호: 5'SS와 3'SS

intron 하나를 제거하려면 먼저 intron의 시작과 끝을 알아야 한다.

```text
[Exon 1] | -------- intron -------- | [Exon 2]
          ^                         ^
         5'SS                      3'SS
```

`5' splice site`, 또는 donor site는 intron이 시작되는 쪽 신호다. `3' splice site`, 또는 acceptor site는 intron이 끝나는 쪽 신호다.

많은 intron은 `GU-AG` 형태의 핵심 신호를 가진다. 여기서 처음에는 "그럼 GU-AG만 찾으면 되는 것 아닌가?"라고 생각하기 쉽다. 하지만 genome에는 비슷하게 생긴 가짜 splice site도 많고, 실제 splice site도 강한 것과 약한 것이 섞여 있다.

질문은 "GU-AG가 있는가?"에서 끝나지 않는다. "이 위치가 실제로 spliceosome에게 선택될 만큼 충분한 문맥과 조절 신호를 갖는가?"까지 봐야 한다.

## 반응 신호: branch point

splicing은 intron 양끝을 단순히 잘라내는 과정이 아니다. intron은 제거될 때 lariat, 즉 올가미 같은 구조를 만들며 빠져나간다. 이 반응을 진행하려면 intron 내부에도 기준점이 필요하다.

```text
[Exon 1] | -------- intron -------- | [Exon 2]
                    ^
               branch point
```

이렇게 보면 `branch point`는 경계 신호라기보다 반응 신호다. intron의 시작과 끝을 알려주는 표지가 아니라, intron 제거 반응을 진행하기 위한 내부 기준점이다.

## 문맥 신호: PPT

`3' splice site`는 `AG` 같은 짧은 신호만으로 안정적으로 인식되기 어렵다. 그 주변에 추가적인 문맥 신호가 붙는 이유다.

```text
branch point ---- polypyrimidine tract ---- 3' splice site
                         ^
                        PPT
```

`polypyrimidine tract`, 즉 PPT는 C 또는 U가 많이 모여 있는 구간이다. 직접 반응을 수행한다기보다는 `3' splice site`가 안정적으로 인식되도록 도와주는 신호로 이해하면 된다.

## 조절 신호: enhancer와 silencer

여기까지가 기본 좌표라면, 실제 splicing에서는 한 가지가 더 남는다. 세포는 다음도 판단해야 한다.

- 이 exon을 포함할 것인가?
- 이 splice site를 실제로 사용할 것인가?
- 가짜 splice site를 억제해야 하는가?

이 판단에 관여하는 신호가 enhancer와 silencer다.

| 신호 | 의미 |
| --- | --- |
| enhancer | 특정 exon 또는 splice site가 사용될 확률을 높이는 신호 |
| silencer | 특정 exon 또는 splice site가 사용될 확률을 낮추거나, 가짜 splice site 사용을 막는 신호 |

enhancer와 silencer는 splicing을 직접 수행하는 가위가 아니다. spliceosome이 어떤 exon 또는 splice site를 선택할지 조절하는 신호다.

위치와 효과를 조합하면 네 가지 이름이 나온다.

| 이름 | 뜻 |
| --- | --- |
| `ESE` | exonic splicing enhancer |
| `ESS` | exonic splicing silencer |
| `ISE` | intronic splicing enhancer |
| `ISS` | intronic splicing silencer |

이 표는 암기표라기보다 조합표다.

- `E` / `I`: exon 안인가, intron 안인가?
- `enhancer` / `silencer`: 사용을 촉진하는가, 억제하는가?

## 확률로 보기

이 부분은 확률로 생각하면 편하다.

어떤 transcript에서 특정 exon이 포함되면 `X = 1`, 빠지면 `X = 0`이라고 하자. 그러면 대략 다음처럼 쓸 수 있다.

$$
X \sim Bernoulli(p)
$$

여기서 `p`는 해당 exon이 mature mRNA에 포함될 확률이다. enhancer와 silencer는 이 `p`를 바꾼다.

| 변화 | 확률 방향 | 대표 결과 |
| --- | --- | --- |
| enhancer loss | exon inclusion 감소 | exon skipping |
| silencer gain | exon inclusion 감소 | exon skipping |
| silencer loss | 억제 해제 | cryptic exon 또는 pseudoexon inclusion |
| enhancer gain | 비정상 후보 강화 | cryptic exon 또는 pseudoexon inclusion |

여기서 enhancer를 "좋은 신호", silencer를 "나쁜 신호"로 보면 다시 헷갈린다. enhancer는 포함 쪽으로 미는 신호이고, silencer는 제외 쪽으로 미는 신호다. 정상적인 splicing에는 둘 다 필요하다. 문제는 variant 때문에 이 균형이 깨질 때 생긴다.

## Synonymous variant는 왜 조용하지 않을 수 있는가

`synonymous variant`는 codon이 바뀌었지만 amino acid는 바뀌지 않는 variant다.

```text
codon 변화
  -> 같은 amino acid 지정
  -> protein sequence만 보면 변화 없음
```

문제는 같은 염기서열이 항상 한 가지 역할만 하지는 않는다는 데 있다.

1. codon으로서 amino acid를 지정한다.
2. splicing motif로서 exon inclusion을 조절한다.

그래서 synonymous variant라도 exon 안의 `ESE`나 `ESS`를 건드릴 수 있다.

```text
synonymous variant
  -> amino acid는 그대로
  -> splicing enhancer/silencer motif가 바뀔 수 있음
  -> exon inclusion probability 변화
  -> exon skipping 또는 pseudoexon inclusion 가능
  -> mature mRNA 구조 변화
  -> protein 결과 변화 가능
```

정리하면, synonymous variant는 amino acid code를 바꾸지 않더라도 splicing code는 바꿀 수 있다.

## DeepRVAT annotation과 weight 설계로 연결하기

DeepRVAT의 annotation 과정은 variant를 모델에 넣기 전에 여러 층의 정보를 붙이는 단계다. VEP 같은 codon-level consequence만 보지 않고, SpliceAI, DeepRiPe, deepSEA, abSplice 같은 annotation을 함께 고려하는 이유도 여기에 있다.

variant weight를 설계할 때도 이 구분을 가져가야 한다.

| 단순한 생각 | 더 나은 생각 |
| --- | --- |
| synonymous니까 영향이 작다 | amino acid는 그대로지만 splicing motif를 바꿀 수 있다 |
| intronic이니까 영향이 작다 | splice site, branch point, PPT, ISE/ISS를 건드릴 수 있다 |
| splice-disrupting이면 곧 PTV다 | splicing disruption은 원인 쪽이고, PTV는 결과 쪽이다 |
| GU-AG만 보면 된다 | splice site 선택은 경계, 반응, 문맥, 조절 신호의 조합으로 결정된다 |

consequence label 하나만으로 weight를 정하기 어려운 이유가 여기에 있다. 적어도 다음 층은 나눠서 보는 편이 낫다.

1. codon-level consequence
2. splice-disruption evidence
3. regulatory motif context
4. final protein-level consequence 가능성

이렇게 보면 synonymous variant에 무조건 낮은 weight를 주는 판단은 위험할 수 있다. 반대로 intronic variant라고 해서 무조건 버리는 것도 마찬가지다. weight를 정할 때 봐야 할 것은 variant가 어떤 좌표계의 어떤 신호를 건드리는지다.

## 정리

splicing motif는 단순한 이름 목록이 아니다. pre-mRNA에서 intron/exon 경계와 exon 포함 여부를 결정하는 분산된 좌표계다.

- `5'SS`, `3'SS`: intron의 시작과 끝을 잡는 경계 신호
- `branch point`: intron 제거 반응의 내부 기준점
- `PPT`: `3' splice site` 인식을 안정화하는 문맥 신호
- `ESE`, `ESS`, `ISE`, `ISS`: exon 또는 splice site 사용 확률을 조절하는 신호

synonymous variant는 amino acid code를 바꾸지 않을 수 있지만, splicing code는 바꿀 수 있다. rare variant annotation에서 synonymous, intronic, splice-disrupting, protein-truncating 같은 표현을 하나의 등급표처럼 읽으면 안 되는 이유다. 서로 다른 축의 정보로 나눠 봐야 weight 설계도 덜 거칠어진다.

<details markdown="1">
<summary>원 필기 이미지 보기</summary>

![Splicing motif 손필기 1](/assets/img/posts/2026-06-29-splicing-motif/note-original-1.png)

![Splicing motif 손필기 2](/assets/img/posts/2026-06-29-splicing-motif/note-original-2.png)

</details>
