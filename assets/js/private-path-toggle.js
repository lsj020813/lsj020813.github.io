(() => {
  const localHosts = new Set(['localhost', '127.0.0.1', '::1']);
  if (!localHosts.has(window.location.hostname)) return;

  const control = document.querySelector('[data-private-path-control]');
  if (!control || !window.crypto?.subtle) return;

  const configScript = document.createElement('script');
  configScript.src = `/assets/js/private-paths.local.js?v=${Date.now()}`;
  configScript.onload = () => {
    if (!window.__PRIVATE_PATHS_ENCRYPTED__) return;
    control.hidden = false;
    initialize(control, window.__PRIVATE_PATHS_ENCRYPTED__);
  };
  document.head.appendChild(configScript);

  function initialize(container, encryptedConfig) {
    const openButton = container.querySelector('[data-private-path-open]');
    const modeLabel = container.querySelector('[data-private-path-mode]');
    const dialog = container.querySelector('[data-private-path-dialog]');
    const form = container.querySelector('[data-private-path-form]');
    const passwordInput = form.elements.password;
    const error = container.querySelector('[data-private-path-error]');
    const cancelButton = container.querySelector('[data-private-path-cancel]');
    let replacements = [];
    let revealed = false;

    openButton.addEventListener('click', () => {
      if (replacements.length) {
        setMode(!revealed);
        return;
      }
      error.textContent = '';
      dialog.showModal();
      passwordInput.focus();
    });

    cancelButton.addEventListener('click', () => {
      passwordInput.value = '';
      dialog.close();
    });

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      error.textContent = '';
      try {
        const mapping = await decryptMapping(passwordInput.value, encryptedConfig);
        replacements = collectReplacements(mapping, container);
        passwordInput.value = '';
        dialog.close();
        setMode(true);
      } catch (_error) {
        passwordInput.value = '';
        error.textContent = '비밀번호가 맞지 않거나 로컬 설정을 읽을 수 없습니다.';
        passwordInput.focus();
      }
    });

    function setMode(showPrivate) {
      replacements.forEach(({ node, publicText, privateText }) => {
        node.nodeValue = showPrivate ? privateText : publicText;
      });
      revealed = showPrivate;
      openButton.textContent = showPrivate ? '공개 경로로 전환' : '절대경로 표시';
      modeLabel.textContent = showPrivate ? '절대경로 모드' : '공개 경로 모드';
    }
  }

  async function decryptMapping(password, config) {
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
      'raw', encoder.encode(password), 'PBKDF2', false, ['deriveKey']
    );
    const key = await crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: decodeBase64(config.salt),
        iterations: config.iterations,
        hash: 'SHA-256'
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    );
    const plaintext = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: decodeBase64(config.iv) },
      key,
      decodeBase64(config.ciphertext)
    );
    return JSON.parse(new TextDecoder().decode(plaintext));
  }

  function collectReplacements(mapping, excludedContainer) {
    const root = document.querySelector('main') || document.body;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const replacements = [];
    let node;

    while ((node = walker.nextNode())) {
      if (excludedContainer.contains(node.parentElement)) continue;
      const publicText = node.nodeValue;
      let privateText = publicText;
      Object.entries(mapping).forEach(([placeholder, absolutePath]) => {
        privateText = privateText.split(placeholder).join(absolutePath);
      });
      if (privateText !== publicText) replacements.push({ node, publicText, privateText });
    }
    return replacements;
  }

  function decodeBase64(value) {
    return Uint8Array.from(atob(value), (character) => character.charCodeAt(0));
  }
})();
