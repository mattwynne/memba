/* Memba — style direction themes + a self-contained StyleTile.
   Each theme is a full look&feel: palette, fonts, radii, voice.
   StyleTile renders identical content under each theme so they're
   directly comparable. Exported to window for the host HTML. */

const THEMES = [
  {
    key: 'forest',
    no: '01',
    name: 'Forest',
    blurb: 'The current direction. Deep forest green, clean Inter, ledger-calm. Structured and quiet.',
    fontDisplay: "'Inter', sans-serif",
    fontBody: "'Inter', sans-serif",
    fontMeta: "'JetBrains Mono', monospace",
    displayWeight: 600, displayTrack: '-0.03em',
    canvas: '#f7f6f3', paper: '#ffffff', line: '#e6e3dc', lineStrong: '#d6d2c8',
    ink: '#15201c', ink2: '#4b5a55', ink3: '#7d877f',
    brand: '#1f4842', brandHover: '#173a35', brandFg: '#ecf2ee',
    accent: '#c46d3a', accentBg: '#f6e6d6', accentInk: '#8a4a22',
    success: '#4f7a5c', successBg: '#e6ece4',
    rBtn: '6px', rCard: '14px', rChip: '999px',
  },
  {
    key: 'clay',
    no: '02',
    name: 'Clay',
    blurb: 'Warmer and friendlier. Terracotta lead, cream paper, soft rounded grotesque. The clubhouse, not the SaaS.',
    fontDisplay: "'Bricolage Grotesque', sans-serif",
    fontBody: "'Hanken Grotesk', sans-serif",
    fontMeta: "'Hanken Grotesk', sans-serif",
    displayWeight: 700, displayTrack: '-0.02em',
    canvas: '#f8f2e9', paper: '#fffdf9', line: '#ece1d2', lineStrong: '#ddcdb8',
    ink: '#2c2018', ink2: '#6b5848', ink3: '#9a8773',
    brand: '#b65a36', brandHover: '#9a4829', brandFg: '#fbeee4',
    accent: '#4f6b4a', accentBg: '#e7ede2', accentInk: '#3a5236',
    success: '#5d7a4a', successBg: '#eaeede',
    rBtn: '999px', rCard: '18px', rChip: '999px',
  },
  {
    key: 'reading',
    no: '03',
    name: 'Reading Room',
    blurb: 'Literary and unhurried. Serif headlines like well-kept minutes, with a warm gold accent.',
    fontDisplay: "'Newsreader', serif",
    fontBody: "'Public Sans', sans-serif",
    fontMeta: "'Public Sans', sans-serif",
    displayWeight: 500, displayTrack: '-0.005em',
    canvas: '#f6f4ee', paper: '#fffdf8', line: '#e4dfd2', lineStrong: '#d4cdb9',
    ink: '#21201b', ink2: '#54514a', ink3: '#857f72',
    brand: '#2f3a24', brandHover: '#222b1a', brandFg: '#eef0e6',
    accent: '#b08930', accentBg: '#f1e8cf', accentInk: '#7a5d1c',
    success: '#5b7148', successBg: '#e9ecde',
    rBtn: '4px', rCard: '8px', rChip: '4px',
  },
  {
    key: 'harbour',
    no: '04',
    name: 'Harbour',
    blurb: 'Cool and coastal. Marine teal on cool stone, crisp grotesque. Made for rowing and sailing clubs.',
    fontDisplay: "'Schibsted Grotesk', sans-serif",
    fontBody: "'Schibsted Grotesk', sans-serif",
    fontMeta: "'JetBrains Mono', monospace",
    displayWeight: 700, displayTrack: '-0.025em',
    canvas: '#f1f3f1', paper: '#ffffff', line: '#dde2df', lineStrong: '#ccd3cf',
    ink: '#16242a', ink2: '#46565c', ink3: '#7a888c',
    brand: '#1d5a63', brandHover: '#154750', brandFg: '#e6f1f1',
    accent: '#c2873f', accentBg: '#f3e7d4', accentInk: '#875829',
    success: '#3f7a6e', successBg: '#dfece9',
    rBtn: '6px', rCard: '10px', rChip: '6px',
  },
  {
    key: 'meadow',
    no: '05',
    name: 'Meadow',
    blurb: 'Light and springy. Soft sage and butter cream, rounded Figtree. The gentlest, most approachable read.',
    fontDisplay: "'Figtree', sans-serif",
    fontBody: "'Figtree', sans-serif",
    fontMeta: "'Figtree', sans-serif",
    displayWeight: 600, displayTrack: '-0.02em',
    canvas: '#f6f5ea', paper: '#fffef9', line: '#e8e6d4', lineStrong: '#d9d6bf',
    ink: '#25291d', ink2: '#555a47', ink3: '#878b76',
    brand: '#5a7050', brandHover: '#475a40', brandFg: '#eef1e6',
    accent: '#d2925a', accentBg: '#f6e8d6', accentInk: '#925f2e',
    success: '#5f7a4f', successBg: '#e9eedd',
    rBtn: '999px', rCard: '16px', rChip: '999px',
  },
  {
    key: 'meadow-forest',
    no: '06',
    name: 'Meadow, squared',
    blurb: "The blend: Meadow's sage, butter cream and Figtree — with Forest's tighter, less-rounded corners. Warm, but composed.",
    fontDisplay: "'Figtree', sans-serif",
    fontBody: "'Figtree', sans-serif",
    fontMeta: "'Figtree', sans-serif",
    displayWeight: 600, displayTrack: '-0.02em',
    canvas: '#f6f5ea', paper: '#fffef9', line: '#e8e6d4', lineStrong: '#d9d6bf',
    ink: '#25291d', ink2: '#555a47', ink3: '#878b76',
    brand: '#5a7050', brandHover: '#475a40', brandFg: '#eef1e6',
    accent: '#d2925a', accentBg: '#f6e8d6', accentInk: '#925f2e',
    success: '#5f7a4f', successBg: '#e9eedd',
    rBtn: '6px', rCard: '12px', rChip: '999px',
  },
];

function StyleTile({ t }) {
  const swatches = [
    { role: 'Canvas', hex: t.canvas, border: true },
    { role: 'Paper', hex: t.paper, border: true },
    { role: 'Ink', hex: t.ink },
    { role: 'Brand', hex: t.brand },
    { role: 'Accent', hex: t.accent },
    { role: 'Success', hex: t.success },
  ];

  const Swatch = ({ role, hex, border }) => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{
        height: 46, borderRadius: 8, background: hex,
        border: border ? `1px solid ${t.lineStrong}` : 'none',
      }} />
      <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        <span style={{ fontFamily: t.fontBody, fontSize: 11, fontWeight: 600, color: t.ink2 }}>{role}</span>
        <span style={{ fontFamily: t.fontMeta, fontSize: 10.5, color: t.ink3, letterSpacing: '0.01em' }}>{hex}</span>
      </div>
    </div>
  );

  const eyebrow = {
    fontFamily: t.fontBody, fontSize: 11.5, fontWeight: 600,
    letterSpacing: '0.08em', textTransform: 'uppercase', color: t.brand,
  };

  return (
    <div style={{
      width: '100%', height: '100%', boxSizing: 'border-box',
      background: t.canvas, padding: '34px 34px 38px',
      display: 'flex', flexDirection: 'column', gap: 26,
      fontFamily: t.fontBody, color: t.ink,
    }}>
      {/* Header */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <span style={{ fontFamily: t.fontMeta, fontSize: 12, color: t.ink3, letterSpacing: '0.04em' }}>
          Direction {t.no}
        </span>
        <h2 style={{
          margin: 0, fontFamily: t.fontDisplay, fontWeight: t.displayWeight,
          fontSize: 46, lineHeight: 1.0, letterSpacing: t.displayTrack, color: t.ink,
        }}>{t.name}</h2>
        <p style={{ margin: 0, fontSize: 14.5, lineHeight: 1.5, color: t.ink2, maxWidth: 460 }}>
          {t.blurb}
        </p>
      </div>

      {/* Palette */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 12 }}>
        {swatches.map((s) => <Swatch key={s.role} {...s} />)}
      </div>

      <div style={{ height: 1, background: t.line }} />

      {/* Type specimen */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <span style={eyebrow}>Type</span>
        <div style={{
          fontFamily: t.fontDisplay, fontWeight: t.displayWeight,
          fontSize: 38, lineHeight: 1.05, letterSpacing: t.displayTrack, color: t.ink,
        }}>Sat 14 Sept</div>
        <div style={{ fontFamily: t.fontDisplay, fontWeight: t.displayWeight, fontSize: 22, color: t.ink, letterSpacing: t.displayTrack }}>
          Ridge walk from Slocan
        </div>
        <p style={{ margin: '2px 0 0', fontSize: 15, lineHeight: 1.55, color: t.ink2, maxWidth: 470 }}>
          Nine spots left. Lou's leading. Meet at the hut for half eight — tea on at the top.
        </p>
      </div>

      {/* Sample trip card */}
      <div style={{
        background: t.paper, border: `1px solid ${t.line}`, borderRadius: t.rCard,
        padding: '18px 20px', boxShadow: '0 1px 2px rgba(21,32,28,0.04)',
        display: 'flex', flexDirection: 'column', gap: 14,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{
              width: 38, height: 38, borderRadius: t.rChip === '999px' ? '999px' : '8px',
              background: t.brand, color: t.brandFg, display: 'grid', placeItems: 'center',
              fontFamily: t.fontBody, fontWeight: 600, fontSize: 14,
            }}>LP</span>
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <span style={{ fontFamily: t.fontBody, fontWeight: 600, fontSize: 15, color: t.ink }}>Lou Pereira</span>
              <span style={{ fontFamily: t.fontMeta, fontSize: 12, color: t.ink3 }}>Trip leader · West Kootenay</span>
            </div>
          </div>
          <span style={{
            fontFamily: t.fontBody, fontSize: 12, fontWeight: 600,
            color: t.accentInk, background: t.accentBg,
            padding: '5px 11px', borderRadius: t.rChip,
          }}>Due soon</span>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button style={{
            fontFamily: t.fontBody, fontSize: 14.5, fontWeight: 600, cursor: 'pointer',
            background: t.brand, color: t.brandFg, border: 'none',
            borderRadius: t.rBtn, padding: '11px 18px',
          }}>Add me to this trip</button>
          <button style={{
            fontFamily: t.fontBody, fontSize: 14.5, fontWeight: 600, cursor: 'pointer',
            background: 'transparent', color: t.ink, border: `1px solid ${t.lineStrong}`,
            borderRadius: t.rBtn, padding: '11px 18px',
          }}>Maybe later</button>
        </div>
      </div>

      {/* Badges */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 'auto', flexWrap: 'wrap' }}>
        <span style={{
          fontFamily: t.fontBody, fontSize: 12.5, fontWeight: 600, color: t.success,
          background: t.successBg, padding: '6px 12px', borderRadius: t.rChip,
        }}>Renewed</span>
        <span style={{
          fontFamily: t.fontBody, fontSize: 12.5, fontWeight: 600, color: t.accentInk,
          background: t.accentBg, padding: '6px 12px', borderRadius: t.rChip,
        }}>Waiver needed</span>
        <span style={{
          fontFamily: t.fontMeta, fontSize: 12, color: t.ink3,
          border: `1px solid ${t.line}`, padding: '6px 12px', borderRadius: t.rChip,
        }}>{t.fontDisplay.replace(/'/g, '').split(',')[0]}</span>
      </div>
    </div>
  );
}

Object.assign(window, { THEMES, StyleTile });
