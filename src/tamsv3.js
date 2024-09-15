import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

const title = "TamsV3";

// Helper function to manipulate inner HTML
const updateElement = (selector, content, attribute = "innerHTML") => {
  const element = document.querySelector(selector);
  if (element) {
    element[attribute] = content;
  }
};

// Helper function to add inline styles
const addStyleToHead = (styleContent) => {
  const style = document.createElement("style");
  style.innerHTML = styleContent;
  document.head.appendChild(style);
};

// Function to stop loading of specific <link> and <script> tags
const stopLoadingTags = (selector = [], retryInterval = 300) => {
  const selectorString = Array.isArray(selector) ? selector.join(",") : '';
  const tryStop = () => {
    const elements = document.querySelectorAll(selectorString);
    elements.forEach((el) => {
      if (el.tagName === 'LINK' && el.rel === 'stylesheet') {
        el.href = ''; // Prevent stylesheet loading
        el.disabled = true; // Disable stylesheet
        el.remove(); // Remove from DOM
      } else if (el.tagName === 'SCRIPT' && el.id !== "important") {
        el.src = ''; // Prevent script loading
        el.type = 'javascript/blocked'; // Set invalid MIME type
        el.remove(); // Remove from DOM
      }
    });

    if (elements.length > 0) {
      setTimeout(tryStop, retryInterval); // Retry if elements still exist
    }
  };

  tryStop(); // Initial call to stop tag loading
};

// Function to remove elements based on a selector
const removeElements = (parent, selector = []) => {
  if (!(parent instanceof HTMLElement || parent instanceof Document)) return;

  const selectorString = Array.isArray(selector) ? selector.join(",") : '';
  parent.querySelectorAll(selectorString).forEach((el) => {
    if (el !== parent && el.id !== "important") {
      try {
        el.remove();
      } catch (err) {
        console.error('Error removing element:', err);
      }
    }
  });
};

// Load event handler for DOM modifications
window.addEventListener('load', () => {
  if (document.body) {
    stopLoadingTags(["link", "script"]); // Stop <link> and <script> loading

    // Set initial styles and attributes
    document.body.style.opacity = '0';
    document.documentElement.setAttribute("data-zee-theme", "dark");
    document.title = title;

    // Update content of specific elements
    updateElement(".text-center", logo, "innerHTML");
    updateElement(".login-logo a", title);
    updateElement('input[name="username"]', "ID Number", "placeholder");

    // Inject styles into the document head
    addStyleToHead(styles);

    // Restore opacity after styling is applied
    document.body.style.transition = 'opacity 0.5s';
    setTimeout(() => {
      document.body.style.opacity = '1';
    }, 600);
  }
}, false);

// Remove unnecessary elements
removeElements(document, ["p.login-box-msg", "span.glyphicon"]);

// Dynamically import Bootstrap and execute
import("bootstrap").then(module => {
  if (typeof module.default === "function") {
    module.default();
  }
});