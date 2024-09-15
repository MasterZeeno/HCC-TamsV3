import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

const title = "TamsV3"

// Function to update the UI (title, logo, placeholders, styles)
const updateUI = () => {
  document.body.style.opacity = '0'  // Hide the body initially

  // Set theme and title
  document.documentElement.setAttribute("data-zee-theme", "dark")
  document.title = title

  // Update logo
  const logoContainer = document.querySelector(".text-center img")?.parentNode
  if (logoContainer) {
    logoContainer.innerHTML = logo
  }

  // Update login anchor text
  const loginAnchor = document.querySelector(".login-logo a")
  if (loginAnchor) {
    loginAnchor.innerHTML = title
  }

  // Update input placeholder
  const usernameInput = document.querySelector('input[name="username"]')
  if (usernameInput) {
    usernameInput.setAttribute("placeholder", "ID Number")
  }

  // Add CSS styles
  const style = document.createElement("style")
  style.innerHTML = styles
  document.head.appendChild(style)
}

// Function to remove elements with retry mechanism
const removeElementsWithRetry = (parent, selector = [], retryInterval = 300) => {
  if (!(parent instanceof HTMLElement || parent instanceof Document)) return

  const selectorString = Array.isArray(selector) ? selector.join(",") : ''

  const tryRemove = () => {
    const elements = parent.querySelectorAll(selectorString)

    elements.forEach((el) => {
      if (el !== parent && el.id !== "important") {
        try {
          el.remove()
        } catch (err) {
          console.error('Error removing element:', err)
        }
      }
    })

    if (elements.length > 0) {
      // Retry if elements are still found
      setTimeout(tryRemove, retryInterval)
    } else {
      // Once all elements are removed, show the body
      document.body.style.opacity = '1'
    }
  }

  // Start removing elements
  tryRemove()
}

// Main event listener for loading the UI
window.addEventListener('load', function() {
  if (document.body) {
    updateUI()  // Update the UI components

    // Remove unwanted elements asynchronously with retries
    removeElementsWithRetry(document, ["p.login-box-msg", "span.glyphicon", "link", "script", "style"])
  }
}, false)

// Import Bootstrap dynamically
import("bootstrap").then(module => {
  if (typeof module.default === "function") {
    module.default()  // Initialize Bootstrap
  }
})