// kise-landing/src/components/LivePalette.tsx
import { useState, useEffect } from "react";

interface Props {
  label: string;
  subtitle: string;
  fallbackCity: string;
  proxyBaseUrl: string;
  description: string;
}

const FALLBACK_COLORS = ["#3A5A40", "#A3B18A", "#588157", "#DAD7CD"];

export default function LivePalette({ label, subtitle, fallbackCity, proxyBaseUrl, description }: Props) {
  const [colors, setColors] = useState<string[]>(FALLBACK_COLORS);
  const [city, setCity] = useState(fallbackCity);
  const [temp, setTemp] = useState<number | null>(null);
  const [condition, setCondition] = useState<string | null>(null);

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
        setCity(weather.city || fallbackCity);
        setTemp(weather.temp);
        setCondition(weather.condition);

        const pickRes = await fetch(`${proxyBaseUrl}/daily-pick`);
        if (pickRes.ok) {
          const pick = await pickRes.json();
          setColors(pick.colors);
          if (!weather.city) {
            setCity(pick.city);
            setTemp(pick.temperature);
            setCondition(pick.condition);
          }
        }
      } catch {
        try {
          const pickRes = await fetch(`${proxyBaseUrl}/daily-pick`);
          if (pickRes.ok) {
            const pick = await pickRes.json();
            setColors(pick.colors);
            setCity(pick.city);
            setTemp(pick.temperature);
            setCondition(pick.condition);
          }
        } catch {
          // Total fallback — static palette
        }
      }
    }

    fetchPalette();
  }, []);

  const cityLine = [city, temp != null ? `${temp}°C` : null, condition]
    .filter(Boolean)
    .join(" · ");

  const descriptionText = description.replace("{city}", city);

  return (
    <section className="-mx-6 bg-pine px-6 py-[140px] text-center">
      <p className="font-body text-sm uppercase tracking-widest text-dust/50">
        {label}
      </p>

      <p className="mx-auto mt-4 max-w-lg whitespace-pre-line font-body text-sm leading-relaxed text-dust/50">
        {subtitle}
      </p>

      <div className="relative mx-auto mt-10 aspect-[4/3] max-w-sm">
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

      <p className="mt-6 font-body text-sm text-dust/70">{cityLine}</p>

      <div className="mt-2 flex justify-center gap-3">
        {colors.map((color, i) => (
          <span key={i} className="font-body text-xs text-dust/40">
            {color.toUpperCase()}
          </span>
        ))}
      </div>

      <p className="mx-auto mt-5 max-w-md whitespace-pre-line font-body text-xs leading-relaxed text-sage/70">
        {descriptionText}
      </p>
    </section>
  );
}
