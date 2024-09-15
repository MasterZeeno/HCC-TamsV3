import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

const title = "TamsV3"

// Function to stop loading of specific <link> and <script> tags
const stopLoadingTags = (selector = [], retryInterval = 300) => {
  const selectorString = Array.isArray(selector) ? selector.join(",") : ''

  const tryStop = () => {
    const elements = document.querySelectorAll(selectorString)

    elements.forEach((el) => {
      if (el.tagName === 'LINK' || el.tagName === 'SCRIPT') {
        try {
          if (el.tagName === 'LINK' && el.rel === 'stylesheet') {
            // Stop stylesheet loading
            el.href = '' // Set href to empty string to stop loading
            el.disabled = true // Disable the stylesheet if not already loaded
          }
          if (el.tagName === 'SCRIPT' && el.id !== "important") {
            // Stop script loading
            el.src = '' // Set src to empty string to prevent further loading
            el.type = 'javascript/blocked' // Change type to invalid MIME to block
          }
          el.remove() // Remove the tag from the DOM
        } catch (err) {
          console.error('Error stopping tag loading:', err)
        }
      }
    })

    if (elements.length > 0) {
      // Retry if there are still elements present
      setTimeout(tryStop, retryInterval)
    }
  }

  // Start the attempt to stop tag loading
  tryStop()
}

window.addEventListener('load', function() {
  if (document.body) {
    stopLoadingTags(["link", "script"])
    
    document.body.style.opacity = '0'
    document.documentElement.setAttribute("data-zee-theme", "dark")
    document.title = title

    const logoContainer = document.querySelector(".text-center img")?.parentNode
    if (logoContainer) {
      logoContainer.innerHTML = logo
    }

    const loginAnchor = document.querySelector(".login-logo a")
    if (loginAnchor) {
      loginAnchor.innerHTML = title
    }

    const usernameInput = document.querySelector('input[name="username"]')
    if (usernameInput) {
      usernameInput.setAttribute("placeholder", "ID Number")
    }

    const style = document.createElement("style")
    style.innerHTML = styles
    document.head.appendChild(style)

    setTimeout(() => {
      document.body.style.opacity = '1'
    }, 600)
  }
}, false)

const removeElements = (parent, selector = []) => {
  if (!(parent instanceof HTMLElement || parent instanceof Document)) return

  const selectorString = Array.isArray(selector) ? selector.join(",") : ''

  parent.querySelectorAll(selectorString).forEach((el) => {
    if (el !== parent && el.id !== "important") {
      try {
        el.remove()
      } catch (err) {
        console.error('Error removing element:', err)
      }
    }
  })
}

removeElements(document, ["p.login-box-msg", "span.glyphicon"])
// removeElements(document, ["link", "script", "style"])

import("bootstrap").then(module => {
  if (typeof module.default === "function") {
    module.default()
  }
})