import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

const title = "TamsV3"

window.addEventListener('load', function() {
  if (document.body) {
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

    setTimeout(() => {
      document.head.appendChild(style)
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
removeElements(document, ["link", "script", "style"])

import("bootstrap").then(module => {
  if (typeof module.default === "function") {
    module.default()
  }
})