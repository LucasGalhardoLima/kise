// kise-landing/src/scripts/waitlist.ts

document.querySelectorAll<HTMLFormElement>("[data-waitlist]").forEach((form) => {
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = new FormData(form).get("email") as string;
    if (!email) return;

    const button = form.querySelector("button")!;
    button.disabled = true;
    button.textContent = "...";

    try {
      const res = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });

      if (res.ok) {
        const successEl = form.nextElementSibling as HTMLElement;
        if (successEl?.hasAttribute("data-waitlist-success")) {
          successEl.classList.remove("hidden");
        }
        form.classList.add("hidden");
      }
    } catch {
      button.disabled = false;
      button.textContent = form.dataset.cta || "Submit";
    }
  });
});
