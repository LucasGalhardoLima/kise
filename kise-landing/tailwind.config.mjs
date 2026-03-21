/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{astro,html,js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        dust: "#DAD7CD",
        sage: "#A3B18A",
        fern: "#588157",
        hunter: "#3A5A40",
        pine: "#344E41",
      },
      fontFamily: {
        brand: ["Cormorant Garamond", "serif"],
        body: ["DM Sans", "sans-serif"],
      },
      maxWidth: {
        content: "720px",
      },
      keyframes: {
        fadeInUp: {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        expandLine: {
          "0%": { width: "0px" },
          "100%": { width: "60px" },
        },
      },
      animation: {
        "fade-in-up":
          "fadeInUp 1.2s cubic-bezier(0.16, 1, 0.3, 1) both",
        "expand-line":
          "expandLine 0.8s cubic-bezier(0.16, 1, 0.3, 1) both",
      },
    },
  },
  plugins: [],
};
