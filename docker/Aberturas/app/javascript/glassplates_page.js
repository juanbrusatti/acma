const GlassplatesPage = (() => {
  const PLACEHOLDERS = {
    planchas: "Buscar planchas por tipo, grosor, color...",
    sobrantes: "Buscar retazos por referencia, tipo, grosor, color...",
  };

  let pageRoot = null;
  let cleanupCallbacks = [];
  let initialized = false;

  function init() {
    if (initialized) return;
    pageRoot = document.querySelector("[data-glassplates-page]");
    if (!pageRoot) return;

    initialized = true;
    cleanupCallbacks = [];

    initializeTabs();
    initializeScrapsImportModal();
    runDebugLogs();

    document.addEventListener("turbo:before-cache", teardown);
  }

  function initializeTabs() {
    const getTabs = () => Array.from(pageRoot.querySelectorAll("[data-tab]"));
    const getContents = () =>
      Array.from(pageRoot.querySelectorAll(".tab-content"));

    if (!getTabs().length || !getContents().length) return;

    const urlParams = new URLSearchParams(window.location.search);
    let initialTab = urlParams.get("tab") || "planchas";
    if (!pageRoot.querySelector(`#${initialTab}-tab`)) {
      initialTab = "planchas";
    }

    setActiveTab(initialTab, getTabs(), getContents());

    const clickHandler = (event) => {
      const tab = event.target.closest("[data-tab]");
      if (!tab || !pageRoot.contains(tab)) return;
      event.preventDefault();

      setActiveTab(tab.getAttribute("data-tab"), getTabs(), getContents());
    };

    pageRoot.addEventListener("click", clickHandler);
    cleanupCallbacks.push(() => pageRoot.removeEventListener("click", clickHandler));
  }

  function setActiveTab(tabName, tabs = [], contents = []) {
    if (!tabs.length) {
      tabs = Array.from(pageRoot.querySelectorAll("[data-tab]"));
    }
    if (!contents.length) {
      contents = Array.from(pageRoot.querySelectorAll(".tab-content"));
    }

    tabs.forEach((tab) => {
      const isActive = tab.getAttribute("data-tab") === tabName;
      tab.classList.toggle("bg-primary", isActive);
      tab.classList.toggle("text-primary-foreground", isActive);
      tab.classList.toggle("shadow-sm", isActive);
      tab.classList.toggle("bg-background", !isActive);
      tab.classList.toggle("text-muted-foreground", !isActive);
    });

    contents.forEach((content) => {
      const shouldShow = content.id === `${tabName}-tab`;
      content.classList.toggle("hidden", !shouldShow);
    });

    updateSearchUI(tabName);
  }

  function updateSearchUI(tabName) {
    const searchInput = pageRoot.querySelector('input[name="search"]');
    const tabInput = document.getElementById("current-tab");
    const placeholder = PLACEHOLDERS[tabName] || PLACEHOLDERS.planchas;

    if (searchInput) {
      searchInput.placeholder = placeholder;
    }
    if (tabInput) {
      tabInput.value = tabName;
    }
  }

  function initializeScrapsImportModal() {
    const importModal = document.getElementById("import-scraps-modal");
    const importBtn = document.getElementById("import-scraps-excel-btn");
    const closeModalBtn = document.getElementById("close-scraps-modal-btn");
    const cancelImportBtn = document.getElementById("cancel-scraps-import-btn");
    const importForm = document.getElementById("import-scraps-form");
    const importErrors = document.getElementById("import-scraps-errors");
    const importSuccess = document.getElementById("import-scraps-success");
    const submitBtn = document.getElementById("submit-scraps-import-btn");

    if (!importModal || !importBtn) return;

    const openModal = () => {
      importModal.classList.remove("hidden");
      importModal.classList.add("flex");
      document.body.style.overflow = "hidden";
    };

    const closeModal = () => {
      importModal.classList.add("hidden");
      importModal.classList.remove("flex");
      document.body.style.overflow = "";

      if (importForm) {
        importForm.reset();
      }
      if (importErrors) {
        importErrors.classList.add("hidden");
        importErrors.textContent = "";
      }
      if (importSuccess) {
        importSuccess.classList.add("hidden");
        importSuccess.textContent = "";
      }
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = "Importar";
      }
    };

    const register = (element, event, handler) => {
      if (!element) return;
      element.addEventListener(event, handler);
      cleanupCallbacks.push(() => element.removeEventListener(event, handler));
    };

    register(importBtn, "click", openModal);
    register(closeModalBtn, "click", closeModal);
    register(cancelImportBtn, "click", closeModal);

    register(importModal, "click", (event) => {
      if (event.target === importModal) {
        closeModal();
      }
    });

    const escHandler = (event) => {
      if (event.key === "Escape" && !importModal.classList.contains("hidden")) {
        closeModal();
      }
    };
    register(document, "keydown", escHandler);

    if (importForm) {
      const submitHandler = (event) => {
        const fileInput = importForm.querySelector('input[type="file"]');
        if (!fileInput || !fileInput.files || fileInput.files.length === 0) {
          event.preventDefault();
          showError("Por favor selecciona un archivo.");
          return;
        }

        const fileName = fileInput.files[0].name;
        const extension = fileName.split(".").pop()?.toLowerCase();
        if (extension !== "xlsx" && extension !== "xls") {
          event.preventDefault();
          showError("El archivo debe ser un Excel (.xlsx o .xls).");
          return;
        }

        if (submitBtn) {
          submitBtn.disabled = true;
          submitBtn.textContent = "Importando...";
        }
      };

      const showError = (message) => {
        if (!importErrors) return;
        importErrors.textContent = message;
        importErrors.classList.remove("hidden");
      };

      register(importForm, "submit", submitHandler);
    }
  }

  function runDebugLogs() {
    if (!window || !window.console) return;
    const editButtons = document.querySelectorAll(".edit-glassplate-btn");
    console.debug("Glassplates page loaded");
    console.debug("Edit buttons found:", editButtons.length);
  }

  function teardown() {
    if (!initialized) return;
    cleanupCallbacks.forEach((fn) => fn());
    cleanupCallbacks = [];

    const importModal = document.getElementById("import-scraps-modal");
    if (importModal) {
      importModal.classList.add("hidden");
      importModal.classList.remove("flex");
      document.body.style.overflow = "";
    }

    pageRoot = null;
    initialized = false;
    document.removeEventListener("turbo:before-cache", teardown);
  }

  return { init, teardown };
})();

document.addEventListener("turbo:load", () => GlassplatesPage.init());
document.addEventListener("turbo:before-cache", () => GlassplatesPage.teardown());

