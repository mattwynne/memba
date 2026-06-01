// Member app — Membership / profile
function ProfileView({ onRenew }) {
  const family = MEMBERS.filter(m => [10, 14].includes(m.id)); // managed family members
  return (
    <div className="fade-in">
      <div className="field-band">
        <span className="page-eyebrow">Your membership</span>
        <h1 className="page-title">Lou Thirgood</h1>
        <p className="page-lede">Member since 1974 · honorary life member.</p>
      </div>

      <div className="card">
        <div className="card__eyebrow">Status</div>
        <h3 className="card__title">Active through 31 March 2027</h3>
        <p className="card__meta">Last renewed 12 April 2026 — £40 received</p>
        <div className="card__row">
          <span className="pill pill--ok"><span className="dot"></span>Renewed</span>
          <button className="btn btn--secondary">View receipts</button>
        </div>
      </div>

      <div className="card">
        <div className="card__eyebrow">Waiver</div>
        <h3 className="card__title">Signed for the 2026 season</h3>
        <p className="card__meta">On file · expires 31 March 2027</p>
        <div className="card__row">
          <span className="pill pill--ok"><span className="dot"></span>On file</span>
          <button className="btn btn--ghost">Read the waiver →</button>
        </div>
      </div>

      <div className="card">
        <div className="card__eyebrow">Your family on the membership</div>
        <h3 className="card__title">Two people you manage</h3>
        <div className="roster-grid" style={{ marginTop: "14px" }}>
          {family.map(m => (
            <div className="roster-person" key={m.id}>
              <div className="av" style={{ background: m.av }}>{m.initials}</div>
              <div className="roster-person__name">{m.name}</div>
              <div className="meta" style={{ fontSize: "12.5px" }}>{m.status === "active" ? "Active" : "Renews soon"}</div>
            </div>
          ))}
        </div>
        <div className="card__row">
          <button className="btn btn--secondary"><Icon name="plus" size={16} /> Add a family member</button>
        </div>
      </div>

      <div className="card">
        <div className="card__eyebrow">Contact</div>
        <h3 className="card__title">How we reach you</h3>
        <p className="card__body">lou@kootenay-alpine.org · 250 555 0184<br/>1218 Lakeshore Rd, Nelson BC</p>
        <div className="card__row">
          <button className="btn btn--secondary">Edit details</button>
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { ProfileView });
