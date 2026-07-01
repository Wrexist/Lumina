// Shared site chrome: scroll-reveal, nav contrast swap over the dark hero,
// and the Support FAQ accordion (single-open via native <details>, no JS
// needed there beyond marking one open by default on load).

document.addEventListener("DOMContentLoaded", () => {
  // ---- Scroll reveal ----
  const revealTargets = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && revealTargets.length) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -60px 0px" }
    );
    revealTargets.forEach((el) => observer.observe(el));
  } else {
    revealTargets.forEach((el) => el.classList.add("is-visible"));
  }

  // ---- Nav contrast: dark hero underneath vs. parchment body ----
  const nav = document.querySelector(".nav");
  const hero = document.querySelector(".hero");
  if (nav && hero && "IntersectionObserver" in window) {
    const navObserver = new IntersectionObserver(
      ([entry]) => nav.classList.toggle("is-on-dark", entry.isIntersecting),
      { rootMargin: "-64px 0px -85% 0px" }
    );
    navObserver.observe(hero);
  } else if (nav && !hero) {
    // Inner pages (Support/Privacy) have no dark hero — nav stays light.
  }
});
