// Member app — Trip detail sheet (with full roster + signup/waitlist)
function TripDetail({ trip, onClose, onSignup }) {
  if (!trip) return null;
  const mine = trip.roster.includes(ME.id);
  const spots = trip.capacity - trip.attending;
  const full = spots <= 0 && !mine;
  const people = trip.roster.map(id => MEMBERS.find(m => m.id === id)).filter(Boolean);
  const leaderName = trip.leader;

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={e => e.stopPropagation()}>
        <button className="sheet__close" onClick={onClose} aria-label="Close">×</button>
        <div className="sheet__date">{trip.month} {trip.day} · {trip.year} · {trip.grade}</div>
        <h2 className="sheet__title">{trip.title}</h2>
        <div className="sheet__meta">{trip.when} · {trip.leader} · {trip.duration} · {trip.dist}</div>
        <p className="sheet__body">{trip.detail}</p>

        <div className="roster-full">
          <div className="card__eyebrow" style={{ marginBottom: "6px" }}>
            On the list · {trip.attending}/{trip.capacity}
          </div>
          <div className="roster-grid">
            {people.map(m => (
              <div className="roster-person" key={m.id}>
                <div className="av" style={{ background: m.av }}>{m.initials}</div>
                <div className="roster-person__name">{m.name}{m.id === ME.id ? " (you)" : ""}</div>
                {m.name === leaderName
                  ? <div className="roster-person__lead">Leader</div>
                  : <div className="meta" style={{ fontSize: "12.5px" }}>{m.town}</div>}
              </div>
            ))}
          </div>
          {full && (
            <div className="waitlist-note">
              <Icon name="alert" size={15} /> This trip is full — you'll join the waitlist and the leader will be in touch.
            </div>
          )}
        </div>

        <div className="sheet__cta" style={{ marginTop: "24px" }}>
          {mine ? (
            <>
              <button className="btn btn--secondary" onClick={() => onSignup(trip, false)}>Take me off the list</button>
              <button className="btn btn--primary" disabled>
                <Icon name="check" size={18} /> You're going
              </button>
            </>
          ) : (
            <>
              <button className="btn btn--secondary" onClick={onClose}>Not now</button>
              <button className="btn btn--primary" onClick={() => onSignup(trip, true)}>
                {full ? "Add me to the waitlist" : "Add me to this trip"}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { TripDetail });
