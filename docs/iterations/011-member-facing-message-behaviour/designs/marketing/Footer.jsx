// Marketing site — footer (no leaves illustration)
function Footer() {
  return (
    <footer className="m-foot">
      <div className="m-foot__inner">
        <div className="m-foot__brand">
          <svg width="24" height="24" viewBox="0 0 64 64" aria-hidden="true">
            <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke="#f6f5ea" strokeWidth="4.8" strokeLinecap="round"/>
            <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="#f6f5ea"/>
            <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="#f6f5ea"/>
            <circle cx="32" cy="15" r="3.7" fill="#d2925a"/>
          </svg>
          <span>memba</span>
        </div>
        <div className="m-foot__cols">
          <div>
            <h5>Product</h5>
            <a href="#">Features</a>
            <a href="#">Pricing</a>
            <a href="#">Changelog</a>
          </div>
          <div>
            <h5>Help</h5>
            <a href="#">Getting started</a>
            <a href="#">Importing members</a>
            <a href="#">Contact support</a>
          </div>
          <div>
            <h5>Memba</h5>
            <a href="#">Who we are</a>
            <a href="#">hello@memba.club</a>
            <a href="#">Privacy</a>
          </div>
        </div>
      </div>
      <div className="m-foot__base">
        <small>© Memba 2026 · Made for clubs that run on volunteers.</small>
      </div>
    </footer>
  );
}

Object.assign(window, { Footer });
