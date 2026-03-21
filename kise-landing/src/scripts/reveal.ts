// Lightweight scroll-reveal using IntersectionObserver
// Respects prefers-reduced-motion

const prefersReducedMotion = window.matchMedia(
  "(prefers-reduced-motion: reduce)"
).matches;

if (prefersReducedMotion) {
  // Immediately reveal all elements for users who prefer reduced motion
  document.querySelectorAll<HTMLElement>("[data-reveal]").forEach((el) => {
    el.classList.add("revealed");
  });
} else {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;

        const el = entry.target as HTMLElement;
        const delay = parseInt(el.dataset.revealDelay || "0", 10);

        if (delay > 0) {
          setTimeout(() => el.classList.add("revealed"), delay);
        } else {
          el.classList.add("revealed");
        }

        observer.unobserve(el);
      });
    },
    { threshold: 0.15 }
  );

  document.querySelectorAll("[data-reveal]").forEach((el) => {
    observer.observe(el);
  });
}
