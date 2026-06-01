// Marketing site — pricing
function Pricing({ onCTA }) {
  const tiers = [
    { name: "Free",     price: "$0",  up: "Up to 50 members",     note: "For small clubs, forever." },
    { name: "Standard", price: "$12", up: "Up to 250 members",    note: "Most clubs land here.", featured: true },
    { name: "Federation", price: "$28", up: "Unlimited members",  note: "For umbrella groups and federations." },
  ];
  return (
    <section className="m-section" id="pricing">
      <div className="m-section__head">
        <span className="eyebrow">Pricing</span>
        <h2>One price, paid yearly.</h2>
      </div>
      <div className="m-pricing">
        {tiers.map(t => (
          <div key={t.name} className={`m-tier ${t.featured ? "m-tier--featured" : ""}`}>
            <div className="m-tier__name">{t.name}</div>
            <div className="m-tier__price">
              <span>{t.price}</span>
              {t.price !== "$0" && <small>/ month, billed yearly</small>}
            </div>
            <div className="m-tier__up">{t.up}</div>
            <p className="m-tier__note">{t.note}</p>
            <button className={`btn ${t.featured ? "btn--primary" : "btn--secondary"}`} onClick={onCTA}>
              {t.price === "$0" ? "Start free" : "Choose " + t.name}
            </button>
          </div>
        ))}
      </div>
    </section>
  );
}

Object.assign(window, { Pricing });
