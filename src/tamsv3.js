import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

window.addEventListener('load', function() {
  if (document.body) {
    const originalDisplay = window.getComputedStyle(document.body).display
    document.body.style.display = 'none'
    setTimeout(() => {
      document.body.style.display = originalDisplay || 'block'
    }, 600)
  }
}, false)

const title = "TamsV3"

const removeElements = (parent, selector = []) => {
  if (!(parent instanceof HTMLElement || parent instanceof Document)) return

  const selectorString = Array.isArray(selector) ? selector.join(",") : selector

  parent.querySelectorAll(selectorString).forEach((el) => {
    if (el !== parent) {
      if (el.id !== "important") {
        try {
          el.remove()
        } catch (err) {
          console.error('Error removing element:', err)
        }
      }
    }
  })
}

removeElements(document, ["p.login-box-msg", "span.glyphicon"])
removeElements(document, ["link", "script", "style"])

document.documentElement.setAttribute("data-zee-theme", "dark")
document.documentElement.setAttribute("style", "background-color: white;")
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

import("bootstrap").then(module => module())