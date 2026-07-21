(() => {
  const root = document.querySelector(".boston-presentation");
  const stageDialog = document.querySelector("#boston-stage-dialog");
  const stageDialogBody = document.querySelector("#stage-dialog-body");
  const ruleDialog = document.querySelector("#boston-rule-dialog");
  const ruleDialogStage = document.querySelector("#rule-dialog-stage");
  const ruleDialogTitle = document.querySelector("#rule-dialog-title");
  const ruleDialogBody = document.querySelector("#rule-dialog-body");
  const ruleDialogPosition = document.querySelector("#rule-dialog-position");

  if (!root || !stageDialog || !ruleDialog) return;

  const ruleLabels = [
    "왜 지금 필요한가",
    "무엇을 계산할까",
    "무엇을 보여줄까",
    "어떻게 판정할까",
    "어떤 도구를 쓸까",
    "어떻게 검증할까",
    "다음 단계에 무엇을 넘길까",
  ];

  const stageRules = {
    0: [
      "데이터를 본 뒤 질문을 바꾸면 결과에 맞춘 설명이 되기 쉽다. 반응변수, 설명변수, 해석 범위를 출발점에서 고정한다.",
      "crim을 반응변수로, 12개 변수를 설명변수로 정한다. 연관성만 해석하며 공통 표본과 수치 허용오차도 함께 기록한다.",
      "데이터 이름, 변수 목록, 유의수준, 신뢰수준, 해석 범위를 한눈에 볼 수 있는 연구 계약표를 보여준다.",
      "crim과 12개 설명변수가 정확히 들어 있고, 인과 해석 문구가 없으면 통과다. 변수 목록이 다르면 분석을 시작하지 않는다.",
      "계약은 Base R의 list와 CSV만으로 충분하다. 아직 모형을 적합하지 않으므로 별도 통계 패키지는 쓰지 않는다.",
      "response가 crim인지, predictors 길이가 12인지, 전체 분석 변수가 13개인지 수작업 기대값과 대조한다.",
      "QC가 검사할 변수 정체성, 허용 범위, 공통 표본의 기준을 1번 단계로 넘긴다.",
    ],
    1: [
      "잘못된 값이나 서로 다른 표본으로 모형을 적합하면 뒤 단계의 계수 비교가 무너진다. 분석 전에 입력과 행을 먼저 고정한다.",
      "필수 변수, 자료형, 유한값, 허용 범위, 중복, 결측을 검사하고 13개 변수의 complete case 표본을 만든다.",
      "전체 행 수, 분석 행 수, 제외 행 수와 각 QC 항목의 PASS·WARN·FAIL을 한 표에 보여준다.",
      "필수 변수나 범위 오류는 FAIL, 결측행 제외는 WARN이다. 분석 가능한 행이 없으면 즉시 중단한다.",
      "교육용 검사는 Base R로 직접 쓰고, 연구용 검사는 checkmate로 같은 규칙을 다시 구현한다.",
      "정상 자료, 결측 자료, chas=2, age=101, crim=-1, rad=2.5 fixture로 통과와 실패가 예상대로 나오는지 확인한다.",
      "동결한 analysis_data와 제외 사유표를 기술통계부터 진단까지 모든 단계에 공통으로 넘긴다.",
    ],
    2: [
      "회귀계수는 변수의 범위와 분포에 영향을 받는다. 평균만 보고 시작하면 치우침과 영향점을 놓치기 쉽다.",
      "표본 수, 결측 수, 평균, 표준편차, 중앙값, IQR, 최솟값, 최댓값을 변수별로 계산한다.",
      "요약통계표와 함께 histogram, boxplot을 보여준다. 발표에서는 모양이 뚜렷하게 다른 변수 몇 개만 고른다.",
      "범위 오류나 표본 수 불일치는 FAIL이다. 큰 치우침과 멀리 떨어진 값은 삭제가 아니라 후속 확인 대상으로 표시한다.",
      "Base R의 summary·hist·boxplot과 연구용 broom·ggplot2 산출물을 같은 표본으로 만든다.",
      "작은 fixture의 평균, 중앙값, 표준편차, IQR을 손으로 계산해 두 구현의 결과와 맞춘다.",
      "변환, 비선형성 확인, 민감도 분석이 필요한 변수 후보를 3번과 8번 단계에 넘긴다.",
    ],
    3: [
      "상관계수와 회귀선은 관계의 모양을 하나의 숫자나 직선으로 줄인다. 그 전에 산점도에서 곡선, 군집, 영향점을 봐야 한다.",
      "연속형 변수는 crim과의 산점도와 선형 추세를, chas는 두 집단의 범죄율 분포를 비교한다.",
      "전체 그림을 나열하지 않고 직선형, 곡선형, 영향점이 두드러진 사례를 골라 나란히 보여준다.",
      "그림만으로 유의성이나 독립적인 효과를 확정하지 않는다. 보이는 패턴은 다음 모형에서 검증할 후보로만 남긴다.",
      "Base R plot과 ggplot2를 쓰되 축 범위, 표본, 집단 정의를 같게 맞춘다.",
      "그림에 쓰인 행 수가 동결 표본과 같은지 확인하고, 선택한 대표 그림이 원자료의 범위를 왜곡하지 않는지 본다.",
      "단순회귀에서 확인할 방향과 비선형성 검정에서 확인할 곡률 후보를 넘긴다.",
    ],
    4: [
      "다중회귀 계수가 얼마나 달라졌는지 말하려면 보정 전 기준선이 필요하다. 그래서 설명변수를 하나씩 먼저 본다.",
      "12개 설명변수마다 crim = β0 + β1X + ε 모형을 적합하고 계수, 표준오차, t, p-value, 신뢰구간, R²를 계산한다.",
      "변수 하나당 한 행인 비보정 결과표와 대표 회귀 그림을 보여준다. p-value보다 계수와 신뢰구간을 앞에 둔다.",
      "모형 적합 실패나 표본 수 불일치는 FAIL이다. p-value가 크다는 이유만으로 변수를 제거하지 않는다.",
      "회귀 엔진은 두 구현 모두 stats::lm을 쓴다. Base R은 coef·summary·confint, 연구용은 broom으로 결과를 정리한다.",
      "fixture에서 직접 계산한 기울기와 lm 계수를 맞추고, 두 구현의 표본 수·계수·신뢰구간을 허용오차 안에서 비교한다.",
      "12개 비보정 계수표를 7번 단계의 기준선으로 넘기고, 눈에 띄는 관계는 5번 중첩 구조와 함께 읽는다.",
    ],
    5: [
      "설명변수들이 같은 지역 구조를 함께 반영하면 단순회귀 계수에 다른 변수의 정보가 섞인다. 보정 전에 중첩 구조를 확인한다.",
      "설명변수 상관행렬과 산점도 행렬을 만들고, 다중회귀 설계행렬에서 VIF를 계산한다.",
      "강한 상관쌍, 변수 군집, VIF를 요약한 표를 보여준다. 숫자만 나열하지 말고 어떤 지역 특성이 겹치는지 설명한다.",
      "높은 상관이나 VIF는 자동 삭제 명령이 아니라 계수 불안정 경고다. 제거 여부는 연구질문과 측정 의미를 함께 보고 정한다.",
      "상관은 Base R의 cor, 그림은 pairs 또는 ggplot2, VIF는 동일한 설계행렬 정의로 계산한다.",
      "작은 상관 fixture로 대각선이 1인지, 행렬이 대칭인지, 완전 중복 변수에서 경고가 나는지 확인한다.",
      "6번 다중회귀와 7번 계수 변화에서 사용할 공선성 해석 근거를 넘긴다.",
    ],
    6: [
      "단순회귀는 다른 지역 특성을 고려하지 않는다. 각 변수의 조건부 연관성을 보려면 12개 변수를 같은 모형에 넣어야 한다.",
      "crim을 반응변수로 하는 다중선형회귀 하나를 적합하고 각 계수, 신뢰구간, 모형 전체 적합도를 계산한다.",
      "보정 계수표와 R², 수정 R², 잔차 표준오차, F 통계량을 보여준다. 변수 단위도 함께 적는다.",
      "공통 표본과 사전 변수 계약을 지키지 않으면 FAIL이다. 유의한 계수를 인과효과로 해석하지 않는다.",
      "두 구현 모두 stats::lm을 쓰고, Base R summary·confint 결과를 broom의 tidy·glance 결과와 맞춘다.",
      "계수 행 수, 자유도, 표본 수, R², 신뢰구간이 두 구현에서 일치하는지 확인한다.",
      "12개 보정 계수와 모형 전체 지표를 7번 비교표와 9번 진단 단계에 넘긴다.",
    ],
    7: [
      "보정 전후 계수의 변화는 설명변수들이 정보를 어떻게 나누는지 보여준다. 단순·다중회귀를 따로 발표하면 이 핵심을 놓친다.",
      "변수별로 비보정 계수, 보정 계수, 절대 차이, 비율, 부호 변화, 신뢰구간 변화를 계산한다.",
      "변화가 큰 변수, 부호가 바뀐 변수, 보정 뒤 신뢰구간이 0을 가로지른 변수를 우선 보여준다.",
      "계수 방향과 표본이 맞지 않으면 FAIL이다. 변화가 작다는 이유로 동일한 효과라고 단정하지 않고 불확실성까지 본다.",
      "두 결과표를 변수명으로 결합하고 Base R merge 또는 동일한 tidy join 로직으로 비교표를 만든다.",
      "모든 변수가 정확히 한 번 결합됐는지, 비율의 분모가 0에 가까운 경우가 따로 표시되는지 확인한다.",
      "변화의 원인을 5번 상관·VIF와 연결하고, 남은 곡률 가능성은 8번 단계로 넘긴다.",
    ],
    8: [
      "선형회귀는 X가 한 단위 늘 때 crim이 늘 같은 양만큼 변한다고 본다. 산점도에 곡률이 보이면 이 가정을 시험해야 한다.",
      "연속형 변수마다 선형모형과 3차 다항모형을 같은 표본에 적합하고 nested model F-test를 계산한다.",
      "선형·비선형 모형 비교표, 원래 p-value, 다중검정 보정값, 대표 곡선 그림을 보여준다.",
      "같은 표본을 쓰지 않은 모형 비교는 FAIL이다. 기각은 3차식이 참이라는 뜻이 아니라 곡률을 고려할 근거로 해석한다.",
      "stats::lm과 anova를 공통 엔진으로 쓰고, 연구용 구현은 broom과 ggplot2로 표와 그림을 정리한다.",
      "선형 자료 fixture에서는 비선형항이 필요 없고, 곡선 fixture에서는 비교 검정이 차이를 잡는지 확인한다.",
      "최종 모형에 반영할 비선형항과 선정 근거를 9번 진단 단계에 넘긴다.",
    ],
    9: [
      "좋은 회귀표도 가정 위반이나 몇 개 영향점에 기대고 있을 수 있다. 결론을 내리기 전에 모형이 틀리는 방식을 확인한다.",
      "잔차-적합값, Q-Q, Scale-Location, leverage, Cook's distance를 계산하고 영향 관측치 제외 민감도 분석을 한다.",
      "대표 진단 그림, 영향점 목록, 제외 전후 핵심 계수 비교와 결론 유지 여부를 보여준다.",
      "이상점은 자동 삭제하지 않는다. 데이터 오류, 실제 희귀 지역, 결론 민감성을 구분하고 심한 가정 위반은 WARN 또는 재모형화로 보낸다.",
      "Base R의 plot.lm과 influence.measures를 기준으로 쓰고, 연구용 그림은 같은 진단값을 ggplot2로 표현한다.",
      "진단값의 관측치 순서와 표본 수가 맞는지, 영향점 제외 전후 모형이 같은 변수 계약을 쓰는지 확인한다.",
      "가정 위반과 영향점의 범위, 민감도 분석 결과, 최종 해석 한계를 발표 결론으로 넘긴다.",
    ],
  };

  let currentStage = 0;
  let currentRule = 0;

  function buildRulePicker(stageNumber) {
    const wrapper = document.createElement("section");
    wrapper.className = "rule-picker";
    wrapper.setAttribute("aria-label", `${stageNumber}번 단계의 1~7 분석 규칙`);

    const heading = document.createElement("div");
    heading.className = "rule-picker-heading";
    heading.innerHTML = `<p class="presentation-kicker">SELECT A RULE</p><h3>원하는 분석 규칙만 선택</h3><p>1–7번을 누르면 이 단계의 해당 규칙만 별도 팝업으로 열립니다.</p>`;
    wrapper.append(heading);

    const grid = document.createElement("div");
    grid.className = "rule-grid";
    ruleLabels.forEach((label, index) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "rule-card";
      button.dataset.stage = String(stageNumber);
      button.dataset.rule = String(index);
      button.innerHTML = `<span>${index + 1}</span><strong>${label}</strong>`;
      grid.append(button);
    });
    wrapper.append(grid);
    return wrapper;
  }

  function openStage(targetId) {
    const source = document.getElementById(targetId);
    if (!source) return;

    currentStage = Number(targetId.replace("boston-stage-", ""));
    const title = source.querySelector("summary strong")?.textContent || `${currentStage}번 단계`;
    const clone = source.querySelector(".stage-content")?.cloneNode(true);
    if (!clone) return;

    const titleNode = document.createElement("h2");
    titleNode.id = "stage-dialog-title";
    titleNode.textContent = `${currentStage}. ${title}`;
    clone.prepend(buildRulePicker(currentStage));
    clone.prepend(titleNode);
    stageDialogBody.replaceChildren(clone);
    stageDialog.showModal();
  }

  function openRule(stageNumber, ruleIndex) {
    const source = document.getElementById(`boston-stage-${stageNumber}`);
    const stageTitle = source?.querySelector("summary strong")?.textContent || `${stageNumber}번 단계`;
    currentStage = stageNumber;
    currentRule = ruleIndex;

    ruleDialogStage.textContent = `${stageNumber}번 단계 · ${stageTitle}`;
    ruleDialogTitle.textContent = `${ruleIndex + 1}. ${ruleLabels[ruleIndex]}`;
    ruleDialogBody.textContent = stageRules[stageNumber][ruleIndex];
    ruleDialogPosition.textContent = `${ruleIndex + 1} / 7`;
    ruleDialog.querySelector('[data-rule-nav="previous"]').disabled = ruleIndex === 0;
    ruleDialog.querySelector('[data-rule-nav="next"]').disabled = ruleIndex === 6;
    if (!ruleDialog.open) ruleDialog.showModal();
  }

  root.addEventListener("click", (event) => {
    const stageButton = event.target.closest("[data-stage-target]");
    if (stageButton) openStage(stageButton.dataset.stageTarget);

    const detailAction = event.target.closest("[data-details-action]");
    if (detailAction) {
      const shouldOpen = detailAction.dataset.detailsAction === "open";
      root.querySelectorAll(".stage-detail").forEach((detail) => {
        detail.open = shouldOpen;
      });
    }
  });

  stageDialog.addEventListener("click", (event) => {
    const ruleButton = event.target.closest(".rule-card");
    if (ruleButton) openRule(Number(ruleButton.dataset.stage), Number(ruleButton.dataset.rule));
    if (event.target === stageDialog || event.target.closest(".stage-dialog-close")) stageDialog.close();
  });

  ruleDialog.addEventListener("click", (event) => {
    if (event.target === ruleDialog || event.target.closest(".rule-dialog-close")) {
      ruleDialog.close();
      return;
    }

    const navButton = event.target.closest("[data-rule-nav]");
    if (!navButton) return;
    const nextRule = navButton.dataset.ruleNav === "next" ? currentRule + 1 : currentRule - 1;
    if (nextRule >= 0 && nextRule <= 6) openRule(currentStage, nextRule);
  });

  [stageDialog, ruleDialog].forEach((dialog) => {
    dialog.addEventListener("close", () => {
      if (dialog === ruleDialog && stageDialog.open) {
        stageDialog.querySelector(`.rule-card[data-rule="${currentRule}"]`)?.focus();
      }
    });
  });
})();
