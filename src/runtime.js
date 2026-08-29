(() => {
  const PHRASE = __PHRASE__;
  const SHORT = __SHORT__;
  const PATTERNS = __PATTERNS__;

  const SKIP_TEXT_TAG = new Set(["SCRIPT", "STYLE", "TEXTAREA", "CODE", "PRE", "KBD", "NOSCRIPT"]);
  const SKIP_TEXT_CLOSEST =
    "textarea, [contenteditable='true'], [data-message-id], [data-md-list-item], .composer-message-codeblock, .ui-markdown__table, .monaco-editor, .monaco-mouse-cursor-text, .view-lines, .xterm, .terminal, .native-edit-context";
  const SKIP_ATTR_CLOSEST =
    "[data-message-id], .composer-message-codeblock, .monaco-editor, .xterm, .terminal";
  const UI_CLOSEST =
    "button, nav, header, footer, h1, h2, h3, h4, label, [role='button'], [role='menuitem'], [role='navigation'], [role='heading'], .action-label, .action-item, .monaco-button, .monaco-text-button, [data-command]";
  const RESOURCE_CLOSEST =
    ".monaco-icon-label, .tabs-container, .breadcrumbs-control, .explorer-folders-view, .scm-view, .search-view";
  const ATTRS = ["placeholder", "title", "aria-label", "aria-placeholder", "alt", "aria-roledescription"];

  let queued = false;
  let observer = null;
  const pending = new Set();
  const observedRoots = new WeakSet();

  const TAIL_PUNCT = { ".": "\u3002", ":": "\uff1a", "!": "\uff01", "?": "\uff1f" };

  function applyMap(s, map) {
    if (!s) return s;
    const t = s.trim();
    if (!t || /[\u4e00-\u9fff]/.test(t)) return s;
    let hit = map[t];
    if (!hit) {
      // 源码中常见 `text${suffix}` 动态拼接结尾标点，词典键不含标点时回退匹配
      const zhTail = TAIL_PUNCT[t.slice(-1)];
      if (zhTail && !t.endsWith("...")) {
        const base = map[t.slice(0, -1).trimEnd()];
        if (base) hit = /[\u3002\uff1a\uff01\uff1f\u2026]$/.test(base) ? base : base + zhTail;
      }
    }
    if (!hit) return s;
    return s.replace(t, hit);
  }

  function applyPatterns(s) {
    const t = s.trim();
    for (const [re, zh] of PATTERNS) {
      if (re.test(t)) return s.replace(t, t.replace(re, zh));
    }
    return s;
  }

  function translate(s, shortOk, patternsOk) {
    const t = (s || "").trim();
    const shortLike = t.length <= 24 && !/\s/.test(t);
    if (shortOk || !shortLike) {
      const phrase = applyMap(s, PHRASE);
      if (phrase !== s) return phrase;
    }
    if (patternsOk) {
      const patterned = applyPatterns(s);
      if (patterned !== s) return patterned;
    }
    if (shortOk) return applyMap(s, SHORT);
    return s;
  }

  function isSkippedText(el) {
    if (!el) return true;
    if (SKIP_TEXT_TAG.has(el.tagName) || el.tagName === "INPUT") return true;
    return !!(el.closest && el.closest(SKIP_TEXT_CLOSEST));
  }

  function isSkippedAttrs(el) {
    if (!el) return true;
    if (SKIP_TEXT_TAG.has(el.tagName)) return true;
    return !!(el.closest && el.closest(SKIP_ATTR_CLOSEST));
  }

  function isResource(el) {
    return !!(el && el.closest && el.closest(RESOURCE_CLOSEST));
  }

  function isUiChrome(el) {
    if (!el || !el.closest) return false;
    if (isResource(el)) return false;
    return !!el.closest(UI_CLOSEST);
  }

  function patchAttrs(el) {
    const shortOk = isUiChrome(el);
    const patternsOk = !isResource(el);
    for (const a of ATTRS) {
      const v = el.getAttribute(a);
      if (!v) continue;
      const nv = translate(v, shortOk || v.length > 12, patternsOk);
      if (nv !== v) el.setAttribute(a, nv);
    }
  }

  function patchText(n) {
    const p = n.parentElement;
    if (isSkippedText(p)) return;
    const nv = translate(n.nodeValue, isUiChrome(p), !isResource(p));
    if (nv !== n.nodeValue) n.nodeValue = nv;
  }

  function observeRoot(root) {
    if (!observer || !root || observedRoots.has(root)) return;
    observer.observe(root, {
      subtree: true,
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ATTRS
    });
    observedRoots.add(root);
  }

  function walk(root) {
    if (!root) return;
    if (root.nodeType === Node.TEXT_NODE) {
      patchText(root);
      return;
    }
    if (root.nodeType === Node.ELEMENT_NODE) {
      if (!isSkippedAttrs(root)) patchAttrs(root);
      if (isSkippedText(root)) return;
      if (root.shadowRoot) {
        observeRoot(root.shadowRoot);
        walk(root.shadowRoot);
      }
    }
    const tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode(n) {
        const p = n.parentElement;
        if (isSkippedText(p)) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    const nodes = [];
    while (tw.nextNode()) nodes.push(tw.currentNode);
    for (const n of nodes) patchText(n);
    if (root.querySelectorAll) {
      root.querySelectorAll("*").forEach((el) => {
        if (isSkippedAttrs(el)) return;
        patchAttrs(el);
        if (el.shadowRoot) {
          observeRoot(el.shadowRoot);
          walk(el.shadowRoot);
        }
      });
    }
  }

  function schedule(records) {
    for (const record of records) {
      if (record.type === "childList") {
        record.addedNodes.forEach((node) => pending.add(node));
      } else {
        pending.add(record.target);
      }
    }
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => {
      queued = false;
      const batch = Array.from(pending);
      pending.clear();
      for (const node of batch) {
        if (node.isConnected !== false) walk(node);
      }
    });
  }

  function boot() {
    observer = new MutationObserver(schedule);
    observeRoot(document.documentElement);
    walk(document.body || document.documentElement);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
