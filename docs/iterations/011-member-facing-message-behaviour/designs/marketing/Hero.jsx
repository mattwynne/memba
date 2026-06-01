// Marketing site — hero (type-only, no illustration)
function Hero({ onCTA, tight, singleCta, showMeta }) {
  const lede = tight
    ? "Membership software for clubs and societies run by volunteers. Renewals, events, and messages — in one place."
    : "Memba is membership software for non-profit societies, clubs, and associations. Take renewals, run events, message your members. Built for volunteer committees, not corporate ops.";
  return (
    <section className="m-hero">
      <div className="m-hero__inner">
        <span className="eyebrow">Membership software for clubs</span>
        <h1 className="m-hero__title">Run your club, not your spreadsheet.</h1>
        <p className="m-hero__lede">{lede}</p>
        <div className="m-hero__cta">
          <button className="btn btn--primary btn--lg" onClick={onCTA}>Get started</button>
          {!singleCta && <a className="btn btn--ghost btn--lg" href="#story">See it in action →</a>}
        </div>
        {showMeta && (
          <div className="m-hero__meta">
            <span>Used by 140+ clubs</span>
            <span className="dot">·</span>
            <span>Free for clubs under 50 members</span>
          </div>
        )}
      </div>
    </section>
  );
}

Object.assign(window, { Hero });
