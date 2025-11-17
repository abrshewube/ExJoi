document.addEventListener("DOMContentLoaded", () => {
  // Initialize common UI first (header, sidebar, footer)
  if (typeof initCommonUI === "function") {
    initCommonUI();
  }
  
  initCopyButtons();
  highlightCode();
  initRolePlayground();
  initAdvancedPlayground();
  initSandbox();
});

function initCopyButtons() {
  const copyButtons = document.querySelectorAll(".copy-btn");
  if (!copyButtons.length) return;

  new ClipboardJS(".copy-btn");
  copyButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      btn.textContent = "Copied!";
      setTimeout(() => (btn.textContent = "Copy"), 1400);
    });
  });
}

function highlightCode() {
  document.querySelectorAll("pre code").forEach((block) => {
    hljs.highlightElement(block);
  });
}

function initRolePlayground() {
  const roleInput = document.getElementById("role-input");
  const permissionsInput = document.getElementById("permissions-input");
  const simulateBtn = document.getElementById("simulate-btn");
  const playgroundOutput = document.getElementById("playground-output");
  if (!roleInput || !simulateBtn || !playgroundOutput) return;

  simulateBtn.addEventListener("click", () => {
    const role = roleInput.value;
    const permissions = permissionsInput.value
      .split(",")
      .map((p) => p.trim())
      .filter(Boolean);

    if (role === "admin" && permissions.length === 0) {
      playgroundOutput.textContent = JSON.stringify(
        {
          status: "error",
          message: "Admin role requires at least one permission.",
        },
        null,
        2
      );
      return;
    }

    playgroundOutput.textContent = JSON.stringify(
      {
        status: "ok",
        message: `Role ${role} passes validation.`,
        permissions,
      },
      null,
      2
    );
  });
}

function initAdvancedPlayground() {
  const nameInput = document.getElementById("pg-name");
  const ageInput = document.getElementById("pg-age");
  const roleInput = document.getElementById("pg-role");
  const permsInput = document.getElementById("pg-perms");
  const dateInput = document.getElementById("pg-date");
  const convertToggle = document.getElementById("pg-convert");
  const runBtn = document.getElementById("pg-run");
  const output = document.getElementById("pg-result");
  if (!nameInput || !runBtn || !output) return;

  runBtn.addEventListener("click", () => {
    const data = {
      name: nameInput.value,
      age: ageInput.value,
      role: roleInput.value,
      permissions: permsInput.value,
      onboarded_at: dateInput.value,
    };

    const result = simulateValidation(data, convertToggle.checked);
    output.textContent = JSON.stringify(result, null, 2);
  });
}

function initSandbox() {
  const dataTextarea = document.getElementById("sandbox-data");
  const convertToggle = document.getElementById("sandbox-convert");
  const runBtn = document.getElementById("sandbox-run");
  const output = document.getElementById("sandbox-output");
  if (!dataTextarea || !runBtn || !output) return;

  runBtn.addEventListener("click", () => {
    try {
      const parsed = JSON.parse(dataTextarea.value);
      const result = simulateValidation(parsed, convertToggle.checked);
      output.textContent = JSON.stringify(result, null, 2);
    } catch (error) {
      output.textContent = JSON.stringify(
        { status: "error", message: `Invalid JSON: ${error.message}` },
        null,
        2
      );
    }
  });
}

function simulateValidation(payload, convert) {
  const errors = {};
  const normalized = {};

  const nameResult = ensureString(payload.name, convert, { min: 2, max: 50 });
  if (nameResult.ok) normalized.name = nameResult.value;
  else addError(errors, ["name"], nameResult.error);

  const ageResult = ensureNumber(payload.age, convert, { min: 18 });
  if (ageResult.ok) normalized.age = ageResult.value;
  else addError(errors, ["age"], ageResult.error);

  const roleResult = ensureString(payload.role, convert, { required: true });
  const requestedRole = roleResult.ok ? roleResult.value : payload.role;
  if (roleResult.ok) normalized.role = roleResult.value;
  else addError(errors, ["role"], roleResult.error);

  const permissionsResult = ensureArray(payload.permissions, convert, { itemMin: 3 });
  if (permissionsResult.ok) {
    normalized.permissions = permissionsResult.value;
  }
  if (requestedRole === "admin") {
    if (!permissionsResult.ok) {
      addError(errors, ["permissions"], permissionsResult.error);
    } else if (permissionsResult.value.length === 0) {
      addError(errors, ["permissions"], { code: "array_min_items", message: "must contain at least 1 item" });
    }
  }

  const dateResult = ensureDate(payload.onboarded_at, convert);
  if (dateResult.ok) normalized.onboarded_at = dateResult.value;
  else addError(errors, ["onboarded_at"], dateResult.error);

  if (Object.keys(errors).length === 0) {
    return { status: "ok", data: normalized };
  }

  return {
    status: "error",
    errors,
    errors_flat: flattenErrors(errors),
  };
}

function ensureString(value, convert, opts = {}) {
  if (typeof value !== "string") {
    if (!convert || value == null) {
      return { ok: false, error: { code: "string", message: "must be a string" } };
    }
    value = String(value);
  }

  let result = value;
  if (convert) {
    result = value.trim().replace(/\s+/g, " ");
  }

  if (opts.required && result.length === 0) {
    return { ok: false, error: { code: "required", message: "is required" } };
  }
  if (opts.min && result.length < opts.min) {
    return { ok: false, error: { code: "string_min", message: `must be at least ${opts.min} characters` } };
  }
  if (opts.max && result.length > opts.max) {
    return { ok: false, error: { code: "string_max", message: `must be at most ${opts.max} characters` } };
  }

  return { ok: true, value: result };
}

function ensureNumber(value, convert, opts = {}) {
  let num = value;
  if (typeof num !== "number") {
    if (!convert || typeof value !== "string") {
      return { ok: false, error: { code: "number", message: "must be a number" } };
    }
    num = Number(value.trim());
  }

  if (!Number.isFinite(num)) {
    return { ok: false, error: { code: "number", message: "must be a number" } };
  }

  if (opts.min != null && num < opts.min) {
    return { ok: false, error: { code: "number_min", message: `must be ≥ ${opts.min}` } };
  }

  if (opts.max != null && num > opts.max) {
    return { ok: false, error: { code: "number_max", message: `must be ≤ ${opts.max}` } };
  }

  return { ok: true, value: num };
}

function ensureArray(value, convert, opts = {}) {
  let arr = value;
  if (!Array.isArray(arr)) {
    if (!convert || typeof value !== "string") {
      return { ok: false, error: { code: "array", message: "must be an array" } };
    }
    arr = value
      .split(opts.delimiter || ",")
      .map((v) => v.trim())
      .filter(Boolean);
  }

  if (opts.minItems && arr.length < opts.minItems) {
    return { ok: false, error: { code: "array_min_items", message: `must contain at least ${opts.minItems} items` } };
  }

  if (opts.itemMin) {
    const failures = arr.reduce((acc, item, idx) => {
      if (item.length < opts.itemMin) acc.push(idx);
      return acc;
    }, []);
    if (failures.length) {
      return {
        ok: false,
        error: {
          code: "string_min",
          message: `item(s) ${failures.join(", ")} must be at least ${opts.itemMin} characters`,
        },
      };
    }
  }

  return { ok: true, value: arr };
}

function ensureDate(value, convert) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    return { ok: true, value: value.toISOString() };
  }

  if (typeof value !== "string") {
    if (!convert) return { ok: false, error: { code: "date", message: "must be ISO8601" } };
    value = String(value);
  }

  const date = new Date(value);
  if (!Number.isNaN(date.getTime())) {
    return { ok: true, value: date.toISOString() };
  }

  return { ok: false, error: { code: "date", message: "must be ISO8601" } };
}

function addError(store, path, error) {
  let cursor = store;
  for (let i = 0; i < path.length - 1; i++) {
    const segment = path[i];
    if (!cursor[segment]) cursor[segment] = {};
    cursor = cursor[segment];
  }
  const leaf = path[path.length - 1];
  cursor[leaf] = cursor[leaf] || [];
  cursor[leaf].push({ code: error.code, message: error.message });
}

function flattenErrors(errors, prefix = []) {
  const flat = {};
  Object.entries(errors).forEach(([key, value]) => {
    const currentPath = [...prefix, key];
    if (Array.isArray(value)) {
      flat[currentPath.join(".")] = value.map((entry) => entry.message);
    } else {
      Object.assign(flat, flattenErrors(value, currentPath));
    }
  });
  return flat;
}
