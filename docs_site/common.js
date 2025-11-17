// Common UI components for ExJoi documentation

function getCurrentPage() {
  const path = window.location.pathname.split("/").pop() || "index.html";
  return path;
}

function getPageTitle(path) {
  const titles = {
    "index.html": "Overview",
    "quickstart.html": "Quick Start",
    "convert-mode.html": "Convert Mode",
    "conditional-rules.html": "Conditional Rules",
    "custom-validators.html": "Custom Validators",
    "error-tree.html": "Error Tree",
    "playground.html": "Playground",
  };
  return titles[path] || "Documentation";
}

function renderHeader() {
  const currentPage = getCurrentPage();
  const pageTitle = getPageTitle(currentPage);
  
  return `
    <header class="sticky top-0 z-50 border-b border-slate-800 bg-slate-950/95 backdrop-blur-xl">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <a href="index.html" class="inline-flex items-center space-x-3 group">
            <div class="h-10 w-10 rounded-xl bg-gradient-to-br from-sky-400 to-emerald-400 flex items-center justify-center text-slate-950 font-black shadow-lg shadow-sky-500/30 group-hover:shadow-sky-500/50 transition-shadow">
              J
            </div>
            <div>
              <p class="font-bold text-white text-lg">ExJoi</p>
              <p class="text-xs text-slate-400">${pageTitle}</p>
            </div>
          </a>
          
          <div class="flex items-center space-x-4">
            <nav class="hidden md:flex items-center space-x-1">
              <a href="index.html" data-nav="index.html" class="nav-link-header">Overview</a>
              <a href="quickstart.html" data-nav="quickstart.html" class="nav-link-header">Quick Start</a>
              <a href="convert-mode.html" data-nav="convert-mode.html" class="nav-link-header">Convert</a>
              <a href="conditional-rules.html" data-nav="conditional-rules.html" class="nav-link-header">Conditionals</a>
              <a href="custom-validators.html" data-nav="custom-validators.html" class="nav-link-header">Custom</a>
              <a href="error-tree.html" data-nav="error-tree.html" class="nav-link-header">Errors</a>
              <a href="playground.html" data-nav="playground.html" class="nav-link-header">Playground</a>
            </nav>
            
            <div class="flex items-center space-x-3">
              <a href="https://hexdocs.pm/exjoi/0.8.0" target="_blank" class="hidden sm:inline-flex items-center px-4 py-2 rounded-full bg-gradient-to-r from-sky-500 to-emerald-400 text-slate-950 font-semibold text-sm hover:shadow-lg hover:shadow-sky-500/30 transition-all">
                HexDocs
              </a>
              <a href="https://github.com/abrshewube/ExJoi" target="_blank" class="hidden sm:inline-flex items-center px-4 py-2 rounded-full border border-slate-700 text-slate-300 font-semibold text-sm hover:bg-slate-800 hover:border-slate-600 transition-all">
                GitHub
              </a>
                  <button id="sidebar-toggle" class="p-2 rounded-lg border border-slate-700 text-slate-300 hover:bg-slate-800 hover:border-slate-600 transition-all">
                <svg id="sidebar-toggle-icon" class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </header>
  `;
}

function renderSidebar() {
  const currentPage = getCurrentPage();
  // Check localStorage for sidebar state (default: open on desktop, closed on mobile)
  // We'll initialize properly in initSidebarToggle
  const savedState = localStorage.getItem('sidebar-open');
  const isOpen = savedState === 'true' || (savedState === null && typeof window !== 'undefined' && window.innerWidth >= 1024);
  
  return `
    <aside id="sidebar" class="fixed inset-y-0 left-0 z-40 w-72 border-r border-slate-800 bg-slate-900/95 backdrop-blur-xl transform transition-transform duration-300 ease-in-out pt-16 ${isOpen ? 'translate-x-0' : '-translate-x-full'}">
      <div class="flex flex-col h-[calc(100vh-4rem)]">
        <div class="flex items-center justify-between p-6 border-b border-slate-800">
          <div class="flex items-center space-x-3">
            <div class="h-10 w-10 rounded-xl bg-gradient-to-br from-sky-400 to-emerald-400 flex items-center justify-center text-slate-950 font-black">J</div>
            <div>
              <p class="text-lg font-semibold text-white">ExJoi</p>
              <p class="text-slate-400 text-sm">Validation, elevated.</p>
            </div>
          </div>
          <button id="sidebar-close" class="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <nav class="flex-1 overflow-y-auto p-6 space-y-1">
          <a href="index.html" data-nav="index.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
            </svg>
            <span>Overview</span>
          </a>
          <a href="quickstart.html" data-nav="quickstart.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
            <span>Quick Start</span>
          </a>
          <a href="convert-mode.html" data-nav="convert-mode.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"></path>
            </svg>
            <span>Convert Mode</span>
          </a>
          <a href="error-tree.html" data-nav="error-tree.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
            <span>Error Tree</span>
          </a>
          <a href="conditional-rules.html" data-nav="conditional-rules.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
            </svg>
            <span>Conditional Rules</span>
          </a>
          <a href="custom-validators.html" data-nav="custom-validators.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
            </svg>
            <span>Custom Validators</span>
          </a>
          <a href="playground.html" data-nav="playground.html" class="sidebar-nav-link">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"></path>
            </svg>
            <span>Live Playground</span>
          </a>
        </nav>
      </div>
    </aside>
    <div id="sidebar-overlay" class="fixed inset-0 bg-black/50 backdrop-blur-sm z-30 opacity-0 pointer-events-none transition-opacity duration-300"></div>
  `;
}

function renderFooter() {
  return `
    <footer id="main-footer" class="border-t border-slate-800 bg-slate-900/50 backdrop-blur-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <div class="flex items-center space-x-3 mb-4">
              <div class="h-10 w-10 rounded-xl bg-gradient-to-br from-sky-400 to-emerald-400 flex items-center justify-center text-slate-950 font-black">J</div>
              <div>
                <p class="font-bold text-white">ExJoi</p>
                <p class="text-xs text-slate-400">Validation, elevated.</p>
              </div>
            </div>
            <p class="text-sm text-slate-400">
              Schema-first validation for Elixir. Built with ❤️ for developers who care about type safety and developer experience.
            </p>
          </div>
          
          <div>
            <h3 class="font-semibold text-white mb-4">Resources</h3>
            <ul class="space-y-2 text-sm">
              <li><a href="https://hexdocs.pm/exjoi/0.8.0" target="_blank" class="text-slate-400 hover:text-sky-400 transition-colors">HexDocs</a></li>
              <li><a href="https://github.com/abrshewube/ExJoi" target="_blank" class="text-slate-400 hover:text-sky-400 transition-colors">GitHub</a></li>
              <li><a href="index.html#roadmap" class="text-slate-400 hover:text-sky-400 transition-colors">Roadmap</a></li>
            </ul>
          </div>
          
          <div>
            <h3 class="font-semibold text-white mb-4">Version</h3>
            <p class="text-sm text-slate-400 mb-2">Current: <span class="text-sky-400 font-semibold">v0.8.0</span></p>
            <p class="text-xs text-slate-500">Error tree + translations</p>
          </div>
        </div>
        
        <div class="mt-8 pt-8 border-t border-slate-800 text-center text-sm text-slate-500">
          <p>Built with Tailwind CSS, highlight.js, and clipboard.js</p>
          <p class="mt-1">ExJoi © ${new Date().getFullYear()}. All rights reserved.</p>
        </div>
      </div>
    </footer>
  `;
}

function initSidebarToggle() {
  const sidebar = document.getElementById("sidebar");
  const sidebarToggle = document.getElementById("sidebar-toggle");
  const sidebarClose = document.getElementById("sidebar-close");
  const sidebarOverlay = document.getElementById("sidebar-overlay");
  const toggleIcon = document.getElementById("sidebar-toggle-icon");
  const mainContent = document.querySelector("main");
  
  function isSidebarOpen() {
    return sidebar && !sidebar.classList.contains("-translate-x-full");
  }
  
  function openSidebar() {
    const footer = document.getElementById("main-footer");
    if (sidebar) {
      sidebar.classList.remove("-translate-x-full");
      localStorage.setItem('sidebar-open', 'true');
    }
    // Show overlay on mobile only
    if (sidebarOverlay && window.innerWidth < 1024) {
      sidebarOverlay.classList.remove("opacity-0", "pointer-events-none");
      sidebarOverlay.classList.add("opacity-100");
      document.body.classList.add("sidebar-open");
    }
    // Add margin to main content and footer on desktop
    if (window.innerWidth >= 1024) {
      if (mainContent) {
        mainContent.classList.add("lg:ml-72");
      }
      if (footer) {
        footer.classList.add("lg:ml-72");
      }
    }
    updateToggleIcon(true);
  }
  
  function closeSidebar() {
    const footer = document.getElementById("main-footer");
    if (sidebar) {
      sidebar.classList.add("-translate-x-full");
      localStorage.setItem('sidebar-open', 'false');
    }
    if (sidebarOverlay) {
      sidebarOverlay.classList.remove("opacity-100");
      sidebarOverlay.classList.add("opacity-0", "pointer-events-none");
    }
    if (mainContent) {
      mainContent.classList.remove("lg:ml-72");
    }
    if (footer) {
      footer.classList.remove("lg:ml-72");
    }
    document.body.classList.remove("sidebar-open");
    updateToggleIcon(false);
  }
  
  function toggleSidebar() {
    if (isSidebarOpen()) {
      closeSidebar();
    } else {
      openSidebar();
    }
  }
  
  function updateToggleIcon(isOpen) {
    if (!toggleIcon) return;
    if (isOpen) {
      // Show close icon (X)
      toggleIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>';
    } else {
      // Show menu icon (hamburger)
      toggleIcon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>';
    }
  }
  
  // Initialize state from localStorage
  const savedState = localStorage.getItem('sidebar-open');
  const isDesktop = window.innerWidth >= 1024;
  
  const footer = document.getElementById("main-footer");
  
  if (savedState === 'true') {
    // Sidebar should be open
    if (sidebar) {
      sidebar.classList.remove("-translate-x-full");
    }
    if (isDesktop) {
      if (mainContent) {
        mainContent.classList.add("lg:ml-72");
      }
      if (footer) {
        footer.classList.add("lg:ml-72");
      }
    }
    updateToggleIcon(true);
    if (!isDesktop && sidebarOverlay) {
      sidebarOverlay.classList.remove("opacity-0", "pointer-events-none");
      sidebarOverlay.classList.add("opacity-100");
      document.body.classList.add("sidebar-open");
    }
  } else if (savedState === 'false') {
    // Sidebar should be closed
    if (sidebar) {
      sidebar.classList.add("-translate-x-full");
    }
    if (mainContent) {
      mainContent.classList.remove("lg:ml-72");
    }
    if (footer) {
      footer.classList.remove("lg:ml-72");
    }
    if (sidebarOverlay) {
      sidebarOverlay.classList.remove("opacity-100");
      sidebarOverlay.classList.add("opacity-0", "pointer-events-none");
    }
    document.body.classList.remove("sidebar-open");
    updateToggleIcon(false);
  } else {
    // Default: open on desktop, closed on mobile
    if (isDesktop) {
      if (sidebar) {
        sidebar.classList.remove("-translate-x-full");
      }
      if (mainContent) {
        mainContent.classList.add("lg:ml-72");
      }
      if (footer) {
        footer.classList.add("lg:ml-72");
      }
      updateToggleIcon(true);
      localStorage.setItem('sidebar-open', 'true');
    } else {
      if (sidebar) {
        sidebar.classList.add("-translate-x-full");
      }
      if (mainContent) {
        mainContent.classList.remove("lg:ml-72");
      }
      if (footer) {
        footer.classList.remove("lg:ml-72");
      }
      updateToggleIcon(false);
    }
  }
  
  sidebarToggle?.addEventListener("click", toggleSidebar);
  sidebarClose?.addEventListener("click", closeSidebar);
  sidebarOverlay?.addEventListener("click", closeSidebar);
  
  // Close sidebar when clicking a link on mobile
  document.querySelectorAll(".sidebar-nav-link").forEach((link) => {
    link.addEventListener("click", () => {
      if (window.innerWidth < 1024) {
        closeSidebar();
      }
    });
  });
  
  // Handle window resize
  let resizeTimer;
  window.addEventListener("resize", () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
      const isDesktop = window.innerWidth >= 1024;
      if (isDesktop && !isSidebarOpen()) {
        // On desktop, if sidebar was closed, check if user wants it open
        const savedState = localStorage.getItem('sidebar-open');
        if (savedState !== 'false') {
          openSidebar();
        }
      }
    }, 250);
  });
}

function initCommonUI() {
  // Inject header
  const headerPlaceholder = document.getElementById("common-header");
  if (headerPlaceholder) {
    headerPlaceholder.outerHTML = renderHeader();
  }
  
  // Inject sidebar (includes overlay)
  const sidebarPlaceholder = document.getElementById("common-sidebar");
  if (sidebarPlaceholder) {
    const sidebarHTML = renderSidebar();
    // Split sidebar and overlay
    const tempDiv = document.createElement("div");
    tempDiv.innerHTML = sidebarHTML;
    const sidebar = tempDiv.querySelector("aside");
    const overlay = tempDiv.querySelector("#sidebar-overlay");
    
    // Store parent and next sibling before replacing
    const parent = sidebarPlaceholder.parentNode;
    const nextSibling = sidebarPlaceholder.nextSibling;
    
    if (sidebar) {
      sidebarPlaceholder.outerHTML = sidebar.outerHTML;
    }
    
    // Insert overlay after sidebar (find the newly inserted sidebar)
    if (overlay && parent) {
      const insertedSidebar = parent.querySelector("aside#sidebar");
      if (insertedSidebar && insertedSidebar.nextSibling) {
        parent.insertBefore(overlay, insertedSidebar.nextSibling);
      } else if (insertedSidebar) {
        parent.appendChild(overlay);
      }
    }
  }
  
  // Inject footer
  const footerPlaceholder = document.getElementById("common-footer");
  if (footerPlaceholder) {
    footerPlaceholder.outerHTML = renderFooter();
  }
  
  // Initialize sidebar toggle after injection
  setTimeout(() => {
    initSidebarToggle();
    enhanceNav();
  }, 0);
}

function enhanceNav() {
  const currentPage = getCurrentPage();
  
  // Update header nav links
  document.querySelectorAll(".nav-link-header").forEach((link) => {
    if (link.dataset.nav === currentPage) {
      link.classList.add("active");
    }
  });
  
  // Update sidebar nav links
  document.querySelectorAll(".sidebar-nav-link").forEach((link) => {
    if (link.dataset.nav === currentPage) {
      link.classList.add("active");
    }
  });
}

