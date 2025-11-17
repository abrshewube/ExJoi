const navLinks = document.querySelectorAll(".nav-link");
const copyButtons = document.querySelectorAll(".copy-btn");

navLinks.forEach((link) => {
  link.classList.add(
    "block",
    "rounded-xl",
    "px-4",
    "py-2",
    "text-slate-400",
    "hover:bg-slate-800",
    "hover:text-white",
    "transition"
  );
});

if (copyButtons.length) {
  new ClipboardJS(".copy-btn");
  copyButtons.forEach((btn) => {
    btn.addEventListener("click", () => {
      btn.textContent = "Copied!";
      setTimeout(() => (btn.textContent = "Copy"), 1400);
    });
  });
}

document.querySelectorAll("pre code").forEach((block) => {
  hljs.highlightElement(block);
});

const roleInput = document.getElementById("role-input");
const permissionsInput = document.getElementById("permissions-input");
const simulateBtn = document.getElementById("simulate-btn");
const playgroundOutput = document.getElementById("playground-output");

const simulate = () => {
  const role = roleInput.value;
  const permissions = permissionsInput.value
    .split(",")
    .map((p) => p.trim())
    .filter(Boolean);

  const needsPermissions = role === "admin";
  let result;

  if (needsPermissions && permissions.length === 0) {
    result = {
      status: "error",
      message: "Admin role requires at least one permission.",
    };
  } else {
    result = {
      status: "ok",
      message: `Role ${role} passes validation.`,
      permissions,
    };
  }

  playgroundOutput.textContent = JSON.stringify(result, null, 2);
};

simulateBtn?.addEventListener("click", simulate);

