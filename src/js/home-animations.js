import { animate } from 'motion/mini'

const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

if (!prefersReducedMotion) {
  const runStagger = (elements, baseDelay = 0, step = 0.08) => {
    elements.forEach((element, index) => {
      animate(
        element,
        { opacity: [0, 1], transform: ['translateY(18px)', 'translateY(0px)'] },
        { duration: 0.5, delay: baseDelay + step * index, easing: 'ease-out', fill: 'forwards' }
      )
    })
  }

  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return
        }

        const element = entry.target
        animate(
          element,
          { opacity: [0, 1], transform: ['translateY(30px)', 'translateY(0px)'] },
          { duration: 0.7, easing: 'cubic-bezier(0.22, 1, 0.36, 1)', fill: 'forwards' }
        )

        observer.unobserve(element)
      })
    },
    { threshold: 0.15, rootMargin: '0px 0px -12% 0px' }
  )

  const staggerObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return
        }

        const container = entry.target
        const items = container.querySelectorAll('.js-anim-stagger-item')
        if (items.length) {
          runStagger(items)
        }

        observer.unobserve(container)
      })
    },
    { threshold: 0.2, rootMargin: '0px 0px -10% 0px' }
  )

  const heroContainer = document.querySelector('.js-anim-hero')
  const heroCard = document.querySelector('.js-anim-fade-up')
  const heroItems = document.querySelectorAll('.js-anim-hero .js-anim-stagger-item')

  if (heroContainer && heroCard) {
    animate(
      heroCard,
      { opacity: [0, 1], transform: ['translateY(24px)', 'translateY(0px)'] },
      { duration: 0.8, easing: 'cubic-bezier(0.22, 1, 0.36, 1)', fill: 'forwards' }
    )

    if (heroItems.length) {
      runStagger(heroItems, 0.1, 0.12)
    }
  }

  document.querySelectorAll('.js-anim-reveal').forEach((element) => revealObserver.observe(element))
  document.querySelectorAll('.js-anim-stagger').forEach((container) => staggerObserver.observe(container))
}
