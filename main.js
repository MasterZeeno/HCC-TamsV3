import fonts from './SF-Pro.css?raw'
import styles from './style.css?raw'
import logo from '/logo.svg?raw'

function removeElements(parent, selector = []) {
  if (!(parent instanceof HTMLElement || parent instanceof Document)) return

  const selectorString = Array.isArray(selector) ? selector.join(",") : selector

  try {
    parent.querySelectorAll(selectorString).forEach((el) => {
      if (el !== parent) {
        if (!el.id || el.id !== 'important') {  // Skip elements with id 'important'
          el.remove()
        }
      }
    })
  } catch (error) {
    console.error("Error in removeElements function:", error)
  }
}

document.addEventListener("DOMContentLoaded", () => {
  // Set a dark theme
  document.documentElement.setAttribute("data-bs-theme", "dark")

  // Insert the logo SVG into the 'div.text-center' element
  const logoContainer = document.querySelector("div.text-center")
  if (logoContainer) {
    logoContainer.innerHTML = logo
  }

  // Uncomment this line to remove specified elements
  removeElements(document, ["link", "style", "script", "div.login-box-msg"])

  Array.from([fonts, styles]).forEach((style) => {
    const styleElem = document.createElement("style")
    styleElem.innerHTML = style
    document.head.appendChild(styleElem)
  })
})