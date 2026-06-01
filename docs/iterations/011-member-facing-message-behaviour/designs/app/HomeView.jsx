// Member app — Home
function HomeView({ setView, openTrip, openCompose }) {
  const hour = new Date().getHours();
  const greet = hour < 12 ? "Morning" : hour < 18 ? "Afternoon" : "Evening";
  const next = TRIPS[0];
  const going = next.roster.includes(ME.id);
  const spots = next.capacity - next.attending;
  return (
    <div className="fade-in">
      <div className="field-band">
        <span className="page-eyebrow">{greet}, Lou</span>
        <h1 className="page-title">Welcome back.</h1>
        <p className="page-lede">A quiet word from the committee, and your next day on the hill.</p>
      </div>

      <div className="card">
        <div className="card__eyebrow">Membership</div>
        <h3 className="card__title">You're a member through 31 March 2027.</h3>
        <p className="card__meta">Waiver on file · last renewed 12 Apr 2026</p>
        <div className="card__row">
          <span className="pill pill--ok"><span className="dot"></span>Active</span>
          <button className="btn btn--ghost" onClick={() => setView("profile")}>View details →</button>
        </div>
      </div>

      <div className="card home-hero">
        <img className="home-hero__art" src="assets/ridgeline.svg" alt="" aria-hidden="true" />
        <div className="card__eyebrow">Your next trip</div>
        <h3 className="card__title">{next.title}</h3>
        <p className="card__meta">{next.when} · {next.leader} · {next.grade}</p>
        <p className="card__body">{next.summary}</p>
        <div className="card__row">
          {going
            ? <span className="pill pill--ok"><span className="dot"></span>You're going</span>
            : <span className="pill pill--info"><span className="dot"></span>{spots} spots left</span>}
          <button className="btn btn--primary" onClick={() => openTrip(next)}>
            {going ? "View the trip →" : "Add me to this trip"}
          </button>
          <button className="btn btn--secondary" onClick={() => setView("trips")}>All trips</button>
        </div>
      </div>

      {ME.committee && (
        <div className="card">
          <div className="card__eyebrow">Committee</div>
          <h3 className="card__title">Something to tell the club?</h3>
          <p className="card__body">You can write to all members, a trip roster, or a single person.</p>
          <div className="card__row">
            <button className="btn btn--secondary" onClick={openCompose}>
              <Icon name="send" size={17} /> Write a message
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
Object.assign(window, { HomeView });
