import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

(function() {
  const title = "TamsV3"

  const removeElements = (parent, selector = []) => {
    if (!(parent instanceof HTMLElement || parent instanceof Document)) return

    const selectorString = Array.isArray(selector) ? selector.join(",") : selector

    parent.querySelectorAll(selectorString).forEach((el) => {
      if (el !== parent) {
        try {
          el.remove()
        } catch (err) {
          console.error('Error removing element:', err)
        }
      }
    })
  }

  // Remove specified elements
  removeElements(document, ["link", "script", "style", "p.login-box-msg", "span.glyphicon"])

  // Set document attributes and title
  document.documentElement.setAttribute("data-zee-theme", "dark")
  document.title = title

  // Update logo
  const logoContainer = document.querySelector(".text-center img")?.parentNode
  if (logoContainer) {
    logoContainer.innerHTML = logo
  }

  // Update login anchor
  const loginAnchor = document.querySelector(".login-logo a")
  if (loginAnchor) {
    loginAnchor.innerHTML = title
  }

  // Update placeholder text for username input
  const usernameInput = document.querySelector('input[name="username"]')
  if (usernameInput) {
    usernameInput.setAttribute("placeholder", "ID Number")
  }

  // Inject raw CSS styles
  const style = document.createElement("style")
  style.innerHTML = styles
  document.head.appendChild(style)
  
  import("bootstrap").then(module => module())
})();