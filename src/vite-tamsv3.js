import logo from './assets/logo.svg?raw'
import styles from './assets/style.css?raw'

const bootstrapInit = async () => {
  try {
    const { Modal, Tooltip } = await import('bootstrap')
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(tooltipTriggerEl => new Tooltip(tooltipTriggerEl))

    const modalEl = document.getElementById('exampleModal')
    if (modalEl) {
      const modalInstance = new Modal(modalEl)
      modalInstance.show()
    }
  } catch (err) {
    console.error('Error loading Bootstrap JS:', err)
  }
}

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

const title = "TamsV3"
removeElements(document, ["p.login-box-msg", "span.glyphicon"])
removeElements(document, ["link", "script", "style"])
document.documentElement.setAttribute("data-zee-theme", "dark")
document.title = title
const logoContainer = document.querySelector(".text-center img").parentNode
if (logoContainer) logoContainer.innerHTML = logo
const loginAnchor = document.querySelector(".login-logo a")
if (loginAnchor) loginAnchor.innerHTML = title
document.querySelector('input[name="username"]').setAttribute("placeholder", "ID Number")
const style = document.createElement("style")
style.innerHTML = styles
document.head.appendChild(style)

bootstrapInit()
