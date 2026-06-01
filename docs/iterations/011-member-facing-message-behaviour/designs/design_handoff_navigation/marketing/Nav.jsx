// Marketing site — top nav
const { useState } = React;

function Nav({ onCTA, minimal }) {
  return (
    <nav className="m-nav">
      <a className="m-nav__brand" href="#">
        <svg width="28" height="28" viewBox="0 0 64 64" aria-hidden="true">
          <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke="#5a7050" strokeWidth="3" strokeLinecap="round"/>
          <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="none" stroke="#5a7050" strokeWidth="2.6" strokeLinejoin="round"/>
          <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="none" stroke="#5a7050" strokeWidth="2.6" strokeLinejoin="round"/>
          <circle cx="32" cy="15" r="3" fill="#d2925a"/>
        </svg>
        <span>memba</span>
      </a>
      {!minimal && (
        <div className="m-nav__links">
          <a href="#features">Product</a>
          <a href="#pricing">Pricing</a>
          <a href="#story">Customers</a>
          <a href="#help">Help</a>
        </div>
      )}
      <div className="m-nav__cta">
        <a href="#signin" className="btn btn--ghost">Sign in</a>
        <button className="btn btn--primary" onClick={onCTA}>Get started</button>
      </div>
    </nav>
  );
}

Object.assign(window, { Nav });
