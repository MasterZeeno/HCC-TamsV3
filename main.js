import logo from './logo.svg?raw'
import 'bootstrap'

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
  const title = "TamsV3"
  // Set a dark theme
  document.documentElement.setAttribute("data-zee-theme", "dark")
  document.title = title
  // Insert the logo SVG into the 'div.text-center' element
  const logoContainer = document.querySelector(".text-center img").parentNode
  if (logoContainer) logoContainer.innerHTML = logo
  const loginAnchor = document.querySelector(".login-logo a")
  if (loginAnchor) loginAnchor.innerHTML = title
  document.querySelector('input[name="username"]').setAttribute("placeholder", "ID Number")
  // Uncomment this line to remove specified elements
  removeElements(document, ["link", "script", "p.login-box-msg", "span.glyphicon"])
})