/* Memba — logo exploration. Six non-literal logomark directions in the
   Meadow-squared palette, each with a small apricot accent dot.
   A Mark renders any concept at any size; c=primary, d=contrast, a=accent
   so the same mark can flip to a sage (inverse) tile cleanly.
   Exported to window: LOGO_CONCEPTS, Mark, LogoTile. */

const SAGE = '#5a7050';
const CREAM = '#f6f5ea';
const APRICOT = '#d2925a';
const INK = '#25291d';

function Mark({ kind, size = 64, c = SAGE, d = CREAM, a = APRICOT }) {
  const p = { width: size, height: size, viewBox: '0 0 64 64', xmlns: 'http://www.w3.org/2000/svg' };
  switch (kind) {
    case 'monogram':
      return (
        <svg {...p}>
          <rect x="6" y="6" width="52" height="52" rx="15" fill={c} />
          <path d="M19 44 V23 L32 36 L45 23 V44" fill="none" stroke={d} strokeWidth="4.4"
            strokeLinecap="round" strokeLinejoin="round" />
          <circle cx="47.5" cy="17" r="3.2" fill={a} />
        </svg>
      );
    case 'card':
      return (
        <svg {...p}>
          <rect x="7" y="16" width="50" height="33" rx="8" fill={c} />
          <rect x="14" y="26" width="17" height="4" rx="2" fill={d} />
          <rect x="14" y="35" width="27" height="4" rx="2" fill={d} opacity="0.55" />
          <circle cx="47" cy="25" r="4.2" fill={a} />
        </svg>
      );
    case 'badge':
      return (
        <svg {...p}>
          <circle cx="32" cy="33" r="24" fill={c} />
          <path d="M21 43 V25 L32 36 L43 25 V43" fill="none" stroke={d} strokeWidth="3.8"
            strokeLinecap="round" strokeLinejoin="round" />
          <circle cx="32" cy="9" r="3.4" fill={a} />
        </svg>
      );
    case 'together':
      return (
        <svg {...p}>
          <circle cx="25" cy="32" r="15" fill="none" stroke={c} strokeWidth="4.2" />
          <circle cx="39" cy="32" r="15" fill="none" stroke={c} strokeWidth="4.2" />
          <circle cx="32" cy="32" r="4.6" fill={a} />
        </svg>
      );
    case 'gathering': {
      const pts = [-90, -30, 30, 90, 150, 210].map((deg) => {
        const r = 19, rad = (deg * Math.PI) / 180;
        return [32 + r * Math.cos(rad), 32 + r * Math.sin(rad)];
      });
      return (
        <svg {...p}>
          {pts.map(([x, y], i) => (
            <circle key={i} cx={x} cy={y} r="5" fill={i === 0 ? a : c} />
          ))}
          <circle cx="32" cy="32" r="3" fill={c} opacity="0.4" />
        </svg>
      );
    }
    case 'arch':
      return (
        <svg {...p}>
          <path d="M16 48 V30 a16 16 0 0 1 32 0 V48" fill="none" stroke={c} strokeWidth="4.4"
            strokeLinecap="round" strokeLinejoin="round" />
          <line x1="12" y1="48" x2="52" y2="48" stroke={c} strokeWidth="4.4" strokeLinecap="round" />
          <circle cx="32" cy="27" r="3.4" fill={a} />
        </svg>
      );
    case 'sprig':
      return (
        <svg {...p}>
          <path d="M32 51 C32 43 32 35 32 19" fill="none" stroke={c} strokeWidth="3.2" strokeLinecap="round" />
          <path d="M32 35 C39 34 45 28 47 18 C38 19.5 33 26 32 35 Z" fill={c} />
          <path d="M32 41 C26 40 21 34 20 25 C27 26.5 31 33 32 41 Z" fill={c} />
          <circle cx="32" cy="16" r="3.3" fill={a} />
        </svg>
      );
    case 'sprigSquare':
      return (
        <svg {...p}>
          <rect x="6" y="6" width="52" height="52" rx="15" fill={c} />
          <path d="M32 49 C32 42 32 35 32 21" fill="none" stroke={d} strokeWidth="3" strokeLinecap="round" />
          <path d="M32 36 C38 35 43 30 45 21 C37 22 33 28 32 36 Z" fill={d} />
          <path d="M32 41 C27 40 22 35 21 27 C27 28 31 34 32 41 Z" fill={d} />
          <circle cx="32" cy="18" r="3.1" fill={a} />
        </svg>
      );
    case 'cardLeaf':
      return (
        <svg {...p}>
          <rect x="7" y="16" width="50" height="33" rx="8" fill={c} />
          <rect x="14" y="26" width="17" height="4" rx="2" fill={d} />
          <rect x="14" y="35" width="27" height="4" rx="2" fill={d} opacity="0.55" />
          <path d="M47 19 C50.5 21.5 50.5 28.5 47 32 C43.5 28.5 43.5 21.5 47 19 Z" fill={a} />
        </svg>
      );
    case 'cardSprig':
      return (
        <svg {...p}>
          <rect x="7" y="18" width="50" height="31" rx="8" fill={c} />
          <rect x="14" y="28" width="16" height="3.8" rx="1.9" fill={d} />
          <rect x="14" y="37" width="23" height="3.8" rx="1.9" fill={d} opacity="0.55" />
          <path d="M46 42 C46 36 46 31 46 23" fill="none" stroke={d} strokeWidth="2.4" strokeLinecap="round" />
          <path d="M46 31 C49.5 30 52 26.5 52.5 21.5 C48.5 22.5 46.5 26.5 46 31 Z" fill={d} />
          <path d="M46 34 C42.5 33 40 29.5 39.5 25 C43.5 26 45.5 29.5 46 34 Z" fill={d} />
          <circle cx="46" cy="20.5" r="2.6" fill={a} />
        </svg>
      );
    case 'seedling':
      return (
        <svg {...p}>
          <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke={c} strokeWidth="3.2" strokeLinecap="round" />
          <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill={c} />
          <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill={c} />
          <circle cx="32" cy="15" r="3.3" fill={a} />
        </svg>
      );
    case 'sprig3':
      return (
        <svg {...p}>
          <path d="M32 52 C32 44 32 30 32 14" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" />
          <path d="M32 26 C38 25 43 20 45 12 C38 13 34 18 32 26 Z" fill={c} />
          <path d="M32 34 C26 33 21 28 20 21 C26 22 31 27 32 34 Z" fill={c} />
          <path d="M32 42 C38 41 42 37 44 30 C38 31 34 35 32 42 Z" fill={c} />
          <circle cx="32" cy="12" r="3" fill={a} />
        </svg>
      );
    case 'sprout':
      return (
        <svg {...p}>
          <path d="M32 50 C32 46 32 42 32 34" fill="none" stroke={c} strokeWidth="3.4" strokeLinecap="round" />
          <path d="M32 36 C24 36 18 32 16 26 C24 24 30 28 32 36 Z" fill={c} />
          <path d="M32 36 C40 36 46 32 48 26 C40 24 34 28 32 36 Z" fill={c} />
          <circle cx="32" cy="29" r="3.4" fill={a} />
        </svg>
      );
    case 'pair':
      return (
        <svg {...p}>
          <path d="M32 52 C32 44 32 30 32 18" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" />
          <path d="M32 32 C25 31 20 26 18 19 C25 20 30 25 32 32 Z" fill={c} />
          <path d="M32 32 C39 31 44 26 46 19 C39 20 34 25 32 32 Z" fill={c} />
          <circle cx="32" cy="15" r="3.3" fill={a} />
        </svg>
      );
    case 'leafVein':
      return (
        <svg {...p}>
          <path d="M32 10 C42 22 42 40 32 52 C22 40 22 22 32 10 Z" fill={c} />
          <path d="M32 15 L32 47" fill="none" stroke={a} strokeWidth="2.6" strokeLinecap="round" />
        </svg>
      );
    case 'lineSprig':
      return (
        <svg {...p}>
          <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" />
          <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="none" stroke={c} strokeWidth="2.6" strokeLinejoin="round" />
          <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="none" stroke={c} strokeWidth="2.6" strokeLinejoin="round" />
          <circle cx="32" cy="15" r="3" fill={a} />
        </svg>
      );
    case 'sprigSolid':
      return (
        <svg {...p}>
          <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke={c} strokeWidth="4.8" strokeLinecap="round" />
          <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill={c} />
          <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill={c} />
          <circle cx="32" cy="15" r="3.7" fill={a} />
        </svg>
      );
    default:
      return null;
  }
}

const LOGO_CONCEPTS = [
  { kind: 'monogram', name: 'Monogram', note: 'A friendly geometric M in the brand square. Reads instantly as a brand, scales tiny.' },
  { kind: 'card', name: 'Member card', note: "Speaks to membership directly — the dot is the member. Warm and literal without being clubby." },
  { kind: 'badge', name: 'Roundel', note: 'A soft club crest. Societies love a badge; the bead at the top is the accent.' },
  { kind: 'together', name: 'Together', note: 'Two rings overlapping — belonging, joining, the union at the centre.' },
  { kind: 'gathering', name: 'Gathering', note: 'People around a circle. The roster, the AGM, the club — one of them is you.' },
  { kind: 'arch', name: 'Threshold', note: 'A doorway — a home for your club. Open, welcoming, place-agnostic.' },
];

function LogoTile({ concept }) {
  const lower = concept.casing === 'lower';
  const wordStyle = {
    fontFamily: "'Figtree', sans-serif", fontWeight: 600, fontSize: 30,
    letterSpacing: '-0.02em', color: INK, lineHeight: 1,
  };
  return (
    <div style={{
      width: '100%', height: '100%', boxSizing: 'border-box', background: CREAM,
      padding: '30px 32px', display: 'flex', flexDirection: 'column', gap: 22,
      fontFamily: "'Figtree', sans-serif", color: INK,
    }}>
      {/* header */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <h3 style={{ margin: 0, fontFamily: "'Figtree', sans-serif", fontWeight: 600, fontSize: 22, letterSpacing: '-0.02em' }}>
          {concept.name}
        </h3>
        <p style={{ margin: 0, fontSize: 13.5, lineHeight: 1.5, color: '#555a47', maxWidth: 400 }}>{concept.note}</p>
      </div>

      {/* mark trio: large on white, inverse on sage, favicon */}
      <div style={{ display: 'flex', alignItems: 'stretch', gap: 14 }}>
        <div style={{ flex: 1, background: '#fffef9', border: `1px solid #e8e6d4`, borderRadius: 12, display: 'grid', placeItems: 'center', padding: '22px 0' }}>
          <Mark kind={concept.kind} size={84} />
        </div>
        <div style={{ width: 110, background: SAGE, borderRadius: 12, display: 'grid', placeItems: 'center' }}>
          <Mark kind={concept.kind} size={56} c={CREAM} d={SAGE} a={APRICOT} />
        </div>
        <div style={{ width: 70, background: '#fffef9', border: `1px solid #e8e6d4`, borderRadius: 12, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 7 }}>
          <Mark kind={concept.kind} size={22} />
          <span style={{ fontSize: 9.5, color: '#878b76' }}>20px</span>
        </div>
      </div>

      <div style={{ height: 1, background: '#e8e6d4' }} />

      {/* lockups */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        {lower ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
            <Mark kind={concept.kind} size={44} />
            <span style={{ ...wordStyle, fontSize: 38 }}>memba</span>
          </div>
        ) : (
          <>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Mark kind={concept.kind} size={36} />
              <span style={wordStyle}>memba</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Mark kind={concept.kind} size={36} />
              <span style={wordStyle}>Memba</span>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { LOGO_CONCEPTS, Mark, LogoTile });
