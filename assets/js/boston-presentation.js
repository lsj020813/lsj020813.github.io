(() => {
  "use strict";

  const report = document.querySelector("#boston-report");
  if (!report) return;

  const chapters = [...report.querySelectorAll(".analysis-chapter")];
  const chapterLinks = [...report.querySelectorAll("[data-chapter-link]")];
  const readingCurrent = report.querySelector("[data-reading-current]");

  const setActiveChapter = (number) => {
    chapterLinks.forEach((link) => {
      const active = Number(link.dataset.chapterLink) === number;
      if (active) link.setAttribute("aria-current", "location");
      else link.removeAttribute("aria-current");
    });
    if (readingCurrent) readingCurrent.textContent = String(number).padStart(2, "0");
  };

  const observer = new IntersectionObserver((entries) => {
    const visible = entries
      .filter((entry) => entry.isIntersecting)
      .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
    if (visible) setActiveChapter(Number(visible.target.dataset.chapter));
  }, { rootMargin: "-20% 0px -65%", threshold: [0, .1, .3] });
  chapters.forEach((chapter) => observer.observe(chapter));
  setActiveChapter(0);

  report.querySelectorAll("[data-expand-rules]").forEach((button) => {
    button.addEventListener("click", () => {
      const chapter = button.closest(".analysis-chapter");
      const rules = [...chapter.querySelectorAll(".research-rule")];
      const shouldOpen = rules.some((rule) => !rule.open);
      rules.forEach((rule) => { rule.open = shouldOpen; });
      button.textContent = shouldOpen ? "모두 접기" : "모두 펼치기";
    });
  });

  report.querySelectorAll("[data-code-workbench]").forEach((workbench) => {
    const tabs = [...workbench.querySelectorAll("[data-code-tab]")];
    const panels = [...workbench.querySelectorAll("[data-code-panel]")];
    const activate = (tab, focus = false) => {
      tabs.forEach((candidate) => {
        const selected = candidate === tab;
        candidate.setAttribute("aria-selected", String(selected));
        candidate.tabIndex = selected ? 0 : -1;
      });
      panels.forEach((panel) => { panel.hidden = panel.dataset.codePanel !== tab.dataset.codeTab; });
      if (focus) tab.focus();
    };
    tabs.forEach((tab, index) => {
      tab.addEventListener("click", () => activate(tab));
      tab.addEventListener("keydown", (event) => {
        let next = null;
        if (event.key === "ArrowRight") next = (index + 1) % tabs.length;
        if (event.key === "ArrowLeft") next = (index - 1 + tabs.length) % tabs.length;
        if (event.key === "Home") next = 0;
        if (event.key === "End") next = tabs.length - 1;
        if (next !== null) { event.preventDefault(); activate(tabs[next], true); }
      });
    });
    workbench.querySelector("[data-copy-code]").addEventListener("click", async (event) => {
      const active = workbench.querySelector("[data-code-panel]:not([hidden]) code");
      try {
        await navigator.clipboard.writeText(active.textContent);
        event.currentTarget.textContent = "복사됨";
      } catch (_error) {
        event.currentTarget.textContent = "선택 후 복사";
        const selection = window.getSelection();
        const range = document.createRange();
        range.selectNodeContents(active); selection.removeAllRanges(); selection.addRange(range);
      }
      window.setTimeout(() => { event.currentTarget.textContent = "복사"; }, 1600);
    });
  });

  const parseCsv = (text) => {
    const rows = [];
    let row = [], field = "", quoted = false;
    for (let index = 0; index < text.length; index += 1) {
      const char = text[index];
      const next = text[index + 1];
      if (char === '"' && quoted && next === '"') { field += '"'; index += 1; }
      else if (char === '"') quoted = !quoted;
      else if (char === "," && !quoted) { row.push(field); field = ""; }
      else if ((char === "\n" || char === "\r") && !quoted) {
        if (char === "\r" && next === "\n") index += 1;
        row.push(field); if (row.some((value) => value !== "")) rows.push(row); row = []; field = "";
      } else field += char;
    }
    if (field || row.length) { row.push(field); rows.push(row); }
    return rows;
  };

  const formatCell = (value) => {
    const numeric = Number(value);
    if (value !== "" && Number.isFinite(numeric)) {
      if (Math.abs(numeric) > 0 && Math.abs(numeric) < .0001) return numeric.toExponential(2);
      if (!Number.isInteger(numeric)) return numeric.toLocaleString("ko-KR", { maximumFractionDigits: 4 });
      return numeric.toLocaleString("ko-KR");
    }
    return value;
  };

  const renderTable = (shell, rows) => {
    const [headers, ...bodyRows] = rows;
    const limit = Number(shell.dataset.tableLimit || 13);
    let data = bodyRows.slice();
    let sortIndex = null;
    let sortDirection = 1;
    const target = shell.querySelector(".table-scroll");
    const status = shell.querySelector(".table-tools span");
    const search = shell.querySelector("[data-table-search]");

    const draw = () => {
      const query = search ? search.value.trim().toLowerCase() : "";
      const filtered = data.filter((row) => !query || row.some((value) => value.toLowerCase().includes(query)));
      const shown = filtered.slice(0, limit);
      const table = document.createElement("table");
      table.className = "data-table";
      const thead = table.createTHead();
      const headRow = thead.insertRow();
      headers.forEach((header, index) => {
        const th = document.createElement("th");
        const button = document.createElement("button");
        button.type = "button"; button.textContent = header; button.dataset.sortIndex = index;
        button.setAttribute("aria-label", `${header} 열 정렬`);
        th.append(button); headRow.append(th);
      });
      const tbody = table.createTBody();
      shown.forEach((values) => {
        const row = tbody.insertRow();
        headers.forEach((header, index) => {
          const cell = row.insertCell(); cell.dataset.label = header; cell.textContent = formatCell(values[index] ?? "");
        });
      });
      target.replaceChildren(table);
      status.textContent = `${filtered.length}행 중 ${shown.length}행 표시`;
      table.querySelectorAll("[data-sort-index]").forEach((button) => {
        button.addEventListener("click", () => {
          const index = Number(button.dataset.sortIndex);
          sortDirection = sortIndex === index ? -sortDirection : 1; sortIndex = index;
          data.sort((a, b) => {
            const aNumber = Number(a[index]), bNumber = Number(b[index]);
            const comparison = Number.isFinite(aNumber) && Number.isFinite(bNumber)
              ? aNumber - bNumber : a[index].localeCompare(b[index], "ko");
            return comparison * sortDirection;
          });
          draw();
        });
      });
    };
    if (search) search.addEventListener("input", draw);
    draw();
  };

  report.querySelectorAll("[data-table-src]").forEach(async (shell) => {
    try {
      const response = await fetch(shell.dataset.tableSrc);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      renderTable(shell, parseCsv(await response.text()));
    } catch (error) {
      shell.querySelector(".table-tools span").textContent = "표를 불러오지 못했습니다";
      shell.dataset.tableError = error.message;
    }
  });

  let presentationIndex = 0;
  let presentationStep = 0;
  const toolbar = document.querySelector("[data-presentation-toolbar]");
  const startButton = report.querySelector("[data-presentation-start]");
  const presentationNumber = toolbar.querySelector("[data-presentation-number]");
  const presentationTitle = toolbar.querySelector("[data-presentation-title]");
  const presentationProgress = toolbar.querySelector("[data-presentation-progress]");
  const unitSelector = ":scope > .chapter-header, :scope > .logic-flow, :scope > .rules-section, :scope > .formula-section, :scope > .implementation-section, :scope > .golden-section, :scope > .actual-results, :scope > .comprehension-gate";

  const updatePresentation = (scroll = true) => {
    chapters.forEach((chapter, index) => chapter.classList.toggle("is-presenting", index === presentationIndex));
    const chapter = chapters[presentationIndex];
    const units = [...chapter.querySelectorAll(unitSelector)];
    presentationStep = Math.max(0, Math.min(presentationStep, units.length - 1));
    units.forEach((unit, index) => unit.classList.toggle("is-presentation-focus", index === presentationStep));
    presentationNumber.textContent = String(presentationIndex).padStart(2, "0");
    presentationTitle.textContent = chapter.querySelector(".chapter-heading h2").textContent;
    presentationProgress.value = presentationIndex + 1;
    presentationProgress.textContent = `${presentationIndex + 1} / ${chapters.length}`;
    toolbar.querySelector("[data-presentation-prev]").disabled = presentationIndex === 0;
    toolbar.querySelector("[data-presentation-next]").disabled = presentationIndex === chapters.length - 1;
    if (scroll) units[presentationStep].scrollIntoView({ block: "start", behavior: "smooth" });
  };
  const enterPresentation = () => {
    const active = chapterLinks.find((link) => link.hasAttribute("aria-current"));
    presentationIndex = active ? Number(active.dataset.chapterLink) : 0;
    presentationStep = 0;
    document.body.classList.add("boston-presentation-active");
    toolbar.hidden = false;
    updatePresentation(false);
    toolbar.querySelector("[data-presentation-next]").focus();
  };
  const exitPresentation = () => {
    document.body.classList.remove("boston-presentation-active");
    toolbar.hidden = true;
    chapters.forEach((chapter) => chapter.classList.remove("is-presenting"));
    startButton.focus();
  };
  const moveChapter = (delta) => {
    presentationIndex = Math.max(0, Math.min(chapters.length - 1, presentationIndex + delta));
    presentationStep = 0; updatePresentation();
  };
  const moveStep = (delta) => {
    const units = [...chapters[presentationIndex].querySelectorAll(unitSelector)];
    const next = presentationStep + delta;
    if (next >= units.length) return moveChapter(1);
    if (next < 0) { moveChapter(-1); presentationStep = [...chapters[presentationIndex].querySelectorAll(unitSelector)].length - 1; }
    else presentationStep = next;
    updatePresentation();
  };

  startButton.addEventListener("click", enterPresentation);
  toolbar.querySelector("[data-presentation-prev]").addEventListener("click", () => moveChapter(-1));
  toolbar.querySelector("[data-presentation-next]").addEventListener("click", () => moveChapter(1));
  toolbar.querySelector("[data-presentation-exit]").addEventListener("click", exitPresentation);
  document.addEventListener("keydown", (event) => {
    if (!document.body.classList.contains("boston-presentation-active")) return;
    if (event.key === "Escape") { event.preventDefault(); exitPresentation(); }
    else if (event.key === "ArrowLeft" || event.key === "PageUp") { event.preventDefault(); moveChapter(-1); }
    else if (event.key === "ArrowRight" || event.key === "PageDown") { event.preventDefault(); moveChapter(1); }
    else if (event.key === " " || event.key === "ArrowDown") { event.preventDefault(); moveStep(1); }
    else if (event.key === "ArrowUp") { event.preventDefault(); moveStep(-1); }
  });
})();
