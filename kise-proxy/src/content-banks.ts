// kise-proxy/src/content-banks.ts

import type { DailyWabiColor, DailyReflection } from "./types";

export const WABI_COLORS: Omit<DailyWabiColor, "type">[] = [
  {
    kanji: "鶯色",
    romanization: "uguisu-iro",
    meaning: "Color of the nightingale",
    hex: "#5B6940",
    poeticDescription:
      "A soft olive green that connects any neutral piece.",
    howToWear: "Wear it when you want presence without volume.",
  },
  {
    kanji: "藍色",
    romanization: "ai-iro",
    meaning: "Japanese indigo",
    hex: "#264F73",
    poeticDescription:
      "The deepest blue there is. In Japan, they say indigo protects whoever wears it.",
    howToWear: "The anchor of any cold-weather palette.",
  },
  {
    kanji: "桜鼠",
    romanization: "sakura-nezumi",
    meaning: "Cherry grey",
    hex: "#B5A4A0",
    poeticDescription: "Not pink, not grey. The space between.",
    howToWear: "Wear it when elegance lives in the details.",
  },
  {
    kanji: "墨色",
    romanization: "sumi-iro",
    meaning: "Ink color",
    hex: "#343434",
    poeticDescription:
      "The black that isn't black. Softer than pure black, deeper than grey.",
    howToWear: "Wear it when you want presence without weight.",
  },
  {
    kanji: "鳥の子色",
    romanization: "torinoko-iro",
    meaning: "Eggshell",
    hex: "#E8DBC5",
    poeticDescription:
      "A warm white that isn't white. The perfect base.",
    howToWear: "It pairs with everything you already own.",
  },
  {
    kanji: "若草色",
    romanization: "wakakusa-iro",
    meaning: "Young grass",
    hex: "#A2C44E",
    poeticDescription: "The most optimistic green there is.",
    howToWear:
      "Wear it when you want the day to start with energy.",
  },
  {
    kanji: "利休鼠",
    romanization: "rikyū-nezumi",
    meaning: "Rikyū's grey",
    hex: "#716F65",
    poeticDescription:
      "A grey with a green soul. Named after the tea master who turned serving tea into art.",
    howToWear: "The color of elegance found in simplicity.",
  },
  {
    kanji: "紅色",
    romanization: "beni-iro",
    meaning: "Safflower red",
    hex: "#CB4042",
    poeticDescription:
      "The Japanese red that pulses without shouting.",
    howToWear:
      "One piece in this color changes the entire composition.",
  },
  {
    kanji: "亜麻色",
    romanization: "ama-iro",
    meaning: "Raw linen",
    hex: "#C2B280",
    poeticDescription:
      "The natural tone of fabric before any dye.",
    howToWear: "The starting point of every intentional wardrobe.",
  },
  {
    kanji: "青磁色",
    romanization: "seiji-iro",
    meaning: "Celadon",
    hex: "#7BA89E",
    poeticDescription:
      "The pale green of Song dynasty ceramics. Calm, materialized.",
    howToWear:
      "Wear it when the day calls for quiet confidence.",
  },
  {
    kanji: "茄子紺",
    romanization: "nasubi-kon",
    meaning: "Eggplant purple",
    hex: "#473946",
    poeticDescription: "Deep, quiet, unexpected.",
    howToWear: "The color that makes people look twice.",
  },
  {
    kanji: "砂色",
    romanization: "suna-iro",
    meaning: "Sand",
    hex: "#C9B9A8",
    poeticDescription: "The neutral that embraces everything.",
    howToWear:
      "It disappears into any combination — and that's its power.",
  },
  {
    kanji: "柿色",
    romanization: "kaki-iro",
    meaning: "Persimmon",
    hex: "#C17435",
    poeticDescription:
      "An earthy orange that warms without dominating.",
    howToWear: "The accent that turns safe into interesting.",
  },
  {
    kanji: "鉄紺",
    romanization: "tetsu-kon",
    meaning: "Iron navy",
    hex: "#17264A",
    poeticDescription: "Navy blue with the weight of metal.",
    howToWear: "Wear it when black feels too obvious.",
  },
  {
    kanji: "白練",
    romanization: "shironeri",
    meaning: "Aged white",
    hex: "#F3ECDB",
    poeticDescription: "White that rested and gained warmth.",
    howToWear: "Softer than white, richer than cream.",
  },
  {
    kanji: "苔色",
    romanization: "koke-iro",
    meaning: "Moss",
    hex: "#696B3B",
    poeticDescription: "The green that grows in silence.",
    howToWear:
      "Pair it with anything grey and watch it come alive.",
  },
  {
    kanji: "灰桜",
    romanization: "hai-zakura",
    meaning: "Ash cherry",
    hex: "#CAB8B2",
    poeticDescription: "Pink that forgot to be pink.",
    howToWear:
      "Subtle enough for anyone, distinctive enough to notice.",
  },
  {
    kanji: "千草色",
    romanization: "chigusa-iro",
    meaning: "Thousand herbs",
    hex: "#317589",
    poeticDescription:
      "A faded blue-green that recalls distance.",
    howToWear: "The color of looking out at the horizon.",
  },
  {
    kanji: "枯草色",
    romanization: "karekusa-iro",
    meaning: "Dry grass",
    hex: "#C4AB6D",
    poeticDescription: "The gold of Japanese autumn.",
    howToWear: "Warmth without heat.",
  },
  {
    kanji: "消炭色",
    romanization: "keshizumi-iro",
    meaning: "Extinguished charcoal",
    hex: "#494B4D",
    poeticDescription: "The most sophisticated grey.",
    howToWear:
      "When you want to disappear and stand out at the same time.",
  },
  {
    kanji: "錆色",
    romanization: "sabi-iro",
    meaning: "Rust",
    hex: "#8B4513",
    poeticDescription: "The color of time passing on metal.",
    howToWear: "Wear it when you want warmth with character.",
  },
  {
    kanji: "薄墨色",
    romanization: "usuzumi-iro",
    meaning: "Diluted ink",
    hex: "#7D7D7D",
    poeticDescription: "Grey with the memory of calligraphy.",
    howToWear: "The most versatile layer in any wardrobe.",
  },
  {
    kanji: "胡桃色",
    romanization: "kurumi-iro",
    meaning: "Walnut",
    hex: "#947A6D",
    poeticDescription: "Brown with warmth baked in.",
    howToWear: "The neutral that feels lived-in from day one.",
  },
  {
    kanji: "深緑",
    romanization: "fukamidori",
    meaning: "Deep green",
    hex: "#004D40",
    poeticDescription: "Forest shade at noon. Concentrated stillness.",
    howToWear: "Wear it when you want gravity without darkness.",
  },
  {
    kanji: "小豆色",
    romanization: "azuki-iro",
    meaning: "Red bean",
    hex: "#96514D",
    poeticDescription: "A red that knows restraint.",
    howToWear: "The warmth of red, without the volume.",
  },
  {
    kanji: "薄藤色",
    romanization: "usufuji-iro",
    meaning: "Pale wisteria",
    hex: "#C4B8D1",
    poeticDescription: "Lavender that almost isn't there.",
    howToWear: "Wear it when softness is the statement.",
  },
  {
    kanji: "老竹色",
    romanization: "oitake-iro",
    meaning: "Aged bamboo",
    hex: "#6B7E63",
    poeticDescription: "The green of bamboo that survived winter.",
    howToWear: "Quiet enough for daily wear. Strong enough to anchor a look.",
  },
  {
    kanji: "練色",
    romanization: "neri-iro",
    meaning: "Unbleached silk",
    hex: "#EDE4D3",
    poeticDescription: "The color of silk before it was asked to be anything else.",
    howToWear: "When white is too cold and cream is too sweet.",
  },
  {
    kanji: "群青色",
    romanization: "gunjō-iro",
    meaning: "Ultramarine",
    hex: "#4C6CB3",
    poeticDescription: "The blue of lapis lazuli ground to powder.",
    howToWear: "Wear it when you want depth without heaviness.",
  },
  {
    kanji: "煤竹色",
    romanization: "susutake-iro",
    meaning: "Smoked bamboo",
    hex: "#6B5344",
    poeticDescription: "Brown darkened by time and fire.",
    howToWear: "The foundation color that makes everything else make sense.",
  },
  {
    kanji: "梅鼠",
    romanization: "ume-nezumi",
    meaning: "Plum grey",
    hex: "#97867C",
    poeticDescription: "A warm grey with a plum undertone hiding inside.",
    howToWear: "The grey that flatters every skin tone.",
  },
  {
    kanji: "翡翠色",
    romanization: "hisui-iro",
    meaning: "Jade",
    hex: "#38B48B",
    poeticDescription: "The green that ancient civilizations treasured.",
    howToWear: "One piece in jade makes an entire outfit memorable.",
  },
  {
    kanji: "朽葉色",
    romanization: "kuchiba-iro",
    meaning: "Decayed leaf",
    hex: "#D09C5C",
    poeticDescription: "Gold earned by falling. The beauty of letting go.",
    howToWear: "Autumn's answer to every neutral question.",
  },
  {
    kanji: "紺鼠",
    romanization: "kon-nezumi",
    meaning: "Navy grey",
    hex: "#4B5A6A",
    poeticDescription: "Where navy dissolves into grey. Both, and neither.",
    howToWear: "The alternative to black that nobody argues with.",
  },
  {
    kanji: "桑染",
    romanization: "kuwazome",
    meaning: "Mulberry dye",
    hex: "#B8860B",
    poeticDescription: "The warm gold of sun through mulberry leaves.",
    howToWear: "Wear it when you want to carry sunlight in your clothes.",
  },
  {
    kanji: "薄花色",
    romanization: "usuhana-iro",
    meaning: "Pale flower",
    hex: "#A0C4E8",
    poeticDescription: "The lightest possible blue. Almost sky, almost nothing.",
    howToWear: "Wear it when every other color feels like too much.",
  },
  {
    kanji: "黄土色",
    romanization: "ōdo-iro",
    meaning: "Ochre",
    hex: "#C49A6C",
    poeticDescription: "Earth, concentrated. The oldest pigment humans ever used.",
    howToWear: "Grounds anything it touches.",
  },
  {
    kanji: "藤鼠",
    romanization: "fuji-nezumi",
    meaning: "Wisteria grey",
    hex: "#A59ACA",
    poeticDescription: "Purple that learned to whisper.",
    howToWear: "Wear it when you want color without commitment.",
  },
  {
    kanji: "胡粉色",
    romanization: "gofun-iro",
    meaning: "Oyster shell white",
    hex: "#F6F0E8",
    poeticDescription: "The warmest white. Made from crushed shells for centuries.",
    howToWear: "The base layer that makes everything else sing.",
  },
  {
    kanji: "鳶色",
    romanization: "tobi-iro",
    meaning: "Kite brown",
    hex: "#6A4028",
    poeticDescription: "The deep brown of a hawk's wing against autumn sky.",
    howToWear: "The leather-jacket brown. Rich, certain, timeless.",
  },
];

export const REFLECTIONS: Omit<DailyReflection, "type">[] = [
  { text: "Repeating an outfit isn't a lack of options. It's confidence." },
  {
    text: "Before buying something new, ask: how many pieces I already own does it talk to?",
  },
  {
    text: "The smartest wardrobe isn't the biggest. It's the one with the fewest pieces that don't talk to each other.",
  },
  {
    text: 'The question isn\'t "what to wear today." It\'s "how do I want to show up today."',
  },
  {
    text: "Every piece you remove makes the ones that stay stronger.",
  },
  { text: "It's not about having more. It's about wearing better." },
  {
    text: "Conscious fashion isn't wearing less. It's wearing with more intention.",
  },
  {
    text: "The best outfit is the one you put together without thinking — because everything in your wardrobe already talks.",
  },
  { text: "Buy less. Choose better. Combine with everything." },
  {
    text: "Your wardrobe tells a story. What story is it telling today?",
  },
  {
    text: "The most versatile piece isn't the most expensive. It's the one that connects with the most combinations.",
  },
  {
    text: "Style isn't following trends. It's knowing what works for you and repeating it with confidence.",
  },
  {
    text: "True luxury is opening your wardrobe and liking everything you see.",
  },
  {
    text: "Fewer decisions in the morning. More confidence all day.",
  },
  {
    text: "An intentional wardrobe is like a well-organized kitchen: fewer ingredients, more possibilities.",
  },
  {
    text: "The piece you wear most is the best piece you own.",
  },
  {
    text: "Dressing with intention doesn't take more time. It takes more awareness.",
  },
  {
    text: "The day you stop impulse buying is the day your wardrobe starts making sense.",
  },
  {
    text: "Three pieces that talk are worth more than thirty that compete.",
  },
  {
    text: "The hardest style to copy is the one that's genuinely yours.",
  },
  {
    text: "A great wardrobe isn't curated in a day. It's edited over years.",
  },
  {
    text: "The color you reach for without thinking is the color that belongs in your wardrobe.",
  },
  {
    text: "Comfort and style aren't opposites. They're the same thing done well.",
  },
  {
    text: "If you wouldn't buy it again today, why is it still in your closet?",
  },
  {
    text: "The most elegant people don't have more clothes. They have fewer doubts.",
  },
  {
    text: "A wardrobe that works is invisible. You notice the person, not the effort.",
  },
  {
    text: "Trends tell you what to want. Style tells you what to ignore.",
  },
  {
    text: "The right shade of white can do more than any statement piece.",
  },
  {
    text: "Getting dressed should feel like a conversation with yourself, not a negotiation.",
  },
  {
    text: "Quality whispers. Fast fashion shouts and then goes quiet.",
  },
  {
    text: "The gap between 'I have nothing to wear' and a great wardrobe is usually subtraction, not addition.",
  },
  {
    text: "Wear your clothes. Don't let your clothes wear you.",
  },
  {
    text: "A capsule wardrobe isn't a number. It's a philosophy: everything earns its place.",
  },
  {
    text: "The best investment piece is the one that makes three other pieces better.",
  },
  {
    text: "Color is the fastest way to change how you feel. Choose intentionally.",
  },
  {
    text: "Minimalism isn't about owning less. It's about owning only what adds.",
  },
  {
    text: "The outfit you wore three times this week isn't boring. It's your uniform. Own it.",
  },
  {
    text: "Good fabric forgives everything. Bad fabric hides nothing.",
  },
  {
    text: "Your wardrobe should make mornings easier, not harder.",
  },
  {
    text: "The most underrated skill in fashion is knowing when something no longer fits who you've become.",
  },
  {
    text: "One well-chosen color can say more than an entire outfit trying too hard.",
  },
];

// Reference Monday for week counting
const REFERENCE_EPOCH_MS = new Date("2026-03-16T00:00:00Z").getTime();
const MS_PER_WEEK = 7 * 86_400_000;

function weeksSinceReference(): number {
  return Math.floor((Date.now() - REFERENCE_EPOCH_MS) / MS_PER_WEEK);
}

export function getWabiColorForToday(dayOfWeek: number): DailyWabiColor {
  const week = weeksSinceReference();
  // Tue = first of the week, Sat = second
  const index = dayOfWeek === 2 ? week * 2 : week * 2 + 1;
  const color = WABI_COLORS[index % WABI_COLORS.length];
  return { type: "wabi-color", ...color };
}

export function getReflectionForToday(): DailyReflection {
  const week = weeksSinceReference();
  const reflection = REFLECTIONS[week % REFLECTIONS.length];
  return { type: "reflection", ...reflection };
}
