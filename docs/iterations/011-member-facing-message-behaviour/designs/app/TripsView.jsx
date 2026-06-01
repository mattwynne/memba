// Member app — Trips listing
function TripCard({ trip, mine, onOpen }) {
  const spots = trip.capacity - trip.attending;
  const full = spots <= 0;
  return (
    <div className={`event-card ${mine ? "is-mine" : ""}`} onClick={() => onOpen(trip)}>
      <div className="event-card__date">
        <div className="m">{trip.month}</div>
        <div className="d">{trip.day}</div>
      </div>
      <div>
        <h4 className="event-card__title">{trip.title}</h4>
        <div className="event-card__meta">{trip.when} · {trip.leader} · {trip.grade}</div>
      </div>
      <div className="event-card__count">
        {mine
          ? <><Icon name="check" size={14} /> You're going</>
          : full ? <span className="muted">Waitlist</span>
          : `${trip.attending} / ${trip.capacity}`}
      </div>
    </div>
  );
}

function TripsView({ trips, onOpen, onPropose }) {
  const [filter, setFilter] = React.useState("all");
  const shown = trips.filter(t => {
    if (filter === "mine") return t.roster.includes(ME.id);
    if (filter === "open") return (t.capacity - t.attending) > 0;
    return true;
  });
  return (
    <div className="fade-in">
      <div className="field-band">
        <div className="page-head">
          <div>
            <span className="page-eyebrow">Summer programme</span>
            <h1 className="page-title">Trips</h1>
          </div>
          {ME.committee && (
            <div className="page-head__actions">
              <button className="btn btn--primary" onClick={onPropose}>
                <Icon name="plus" size={18} /> Propose a trip
              </button>
            </div>
          )}
        </div>
      </div>

      <div style={{ marginBottom: "18px" }}>
        <div className="seg">
          {[["all", "All trips"], ["mine", "Mine"], ["open", "Spots open"]].map(([id, label]) => (
            <button key={id} className={filter === id ? "is-active" : ""} onClick={() => setFilter(id)}>{label}</button>
          ))}
        </div>
      </div>

      <div className="events-list">
        {shown.length === 0
          ? <div className="dir-empty">Nothing here yet.</div>
          : shown.map(t => <TripCard key={t.id} trip={t} mine={t.roster.includes(ME.id)} onOpen={onOpen} />)}
      </div>
    </div>
  );
}
Object.assign(window, { TripCard, TripsView });
