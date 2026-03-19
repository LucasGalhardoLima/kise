// kise-landing/src/components/LivePalette.tsx
import { useState, useEffect } from "react";

interface Props {
  label: string;
  fallbackCity: string;
  proxyBaseUrl: string;
  description: string;
}

const FALLBACK_COLORS = ["#3A5A40", "#A3B18A", "#588157", "#DAD7CD"];

export default function LivePalette({ label, fallbackCity, proxyBaseUrl, description }: Props) {
  const [colors, setColors] = useState<string[]>(FALLBACK_COLORS);
  const [city, setCity] = useState(fallbackCity);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchPalette() {
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) =>
          navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000 })
        );

        const { latitude, longitude } = pos.coords;
        const weatherRes = await fetch(
          `${proxyBaseUrl}/weather?lat=${latitude}&lon=${longitude}`
        );
        const weather = await weatherRes.json();

        const pickRes = await fetch(`${proxyBaseUrl}/daily-pick`);
        if (pickRes.ok) {
          const pick = await pickRes.json();
          setColors(pick.colors);
          setCity(weather.city || pick.city);
        } else {
          setCity(weather.city || fallbackCity);
        }
      } catch {
        try {
          const pickRes = await fetch(`${proxyBaseUrl}/daily-pick`);
          if (pickRes.ok) {
            const pick = await pickRes.json();
            setColors(pick.colors);
            setCity(pick.city);
          }
        } catch {
          // Total fallback — static palette
        }
      } finally {
        setLoading(false);
      }
    }

    fetchPalette();
  }, []);

  const descriptionText = description.replace("{city}", city);

  return (
    <section className="py-20 text-center">
      <p className="font-body text-sm uppercase tracking-widest text-pine/50">
        {label}
      </p>

      <div className="relative mx-auto mt-6 aspect-[4/3] max-w-sm">
        {colors.map((color, i) => {
          const positions = [
            { left: "5%", top: "15%", width: "55%", height: "55%" },
            { left: "25%", top: "5%", width: "50%", height: "40%" },
            { left: "45%", top: "55%", width: "40%", height: "35%" },
            { left: "10%", top: "60%", width: "30%", height: "25%" },
          ];
          const pos = positions[i];
          if (!pos) return null;
          return (
            <div
              key={i}
              className="absolute shadow-sm transition-all duration-700"
              style={{ background: color, ...pos }}
            />
          );
        })}
      </div>

      <p className="mt-4 font-body text-sm text-pine/50">{city}</p>

      <div className="mt-2 flex justify-center gap-3">
        {colors.map((color, i) => (
          <span key={i} className="font-body text-xs text-pine/40">
            {color.toUpperCase()}
          </span>
        ))}
      </div>

      <p className="mx-auto mt-4 max-w-md font-body text-xs leading-relaxed text-pine/40">
        {descriptionText}
      </p>
    </section>
  );
}
