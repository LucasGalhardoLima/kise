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
    },
  },
  plugins: [],
};
