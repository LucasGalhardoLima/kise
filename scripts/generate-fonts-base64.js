import fs from 'fs';
import path from 'path';

const fontsDir = '/Users/lucasgalhardo/Documents/Projects/vesti/KISE/Sources/Resources/Fonts';
const fonts = [
  'CormorantGaramond-Light.ttf',
  'DMSans-Light.ttf',
  'DMSans-Medium.ttf',
  'DMSans-Regular.ttf'
];

let tsContent = '// kise-proxy/src/fonts.ts\n\n';

for (const font of fonts) {
  const fontPath = path.join(fontsDir, font);
  const base64 = fs.readFileSync(fontPath).toString('base64');
  const varName = font.replace('.ttf', '').replace(/-/g, '_');
  tsContent += `export const ${varName} = "${base64}";\n\n`;
}

fs.writeFileSync('kise-proxy/src/fonts.ts', tsContent);
console.log('Fonts generated in kise-proxy/src/fonts.ts');
