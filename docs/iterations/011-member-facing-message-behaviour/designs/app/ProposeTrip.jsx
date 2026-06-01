// Member app — Propose a trip (committee) sheet form
function ProposeTrip({ open, onClose, onSubmit }) {
  if (!open) return null;
  const [f, setF] = React.useState({ title: "", date: "", time: "06:30", leader: ME.name, grade: "Moderate", capacity: "8", summary: "" });
  const set = (k) => (e) => setF({ ...f, [k]: e.target.value });
  const valid = f.title.trim() && f.date && f.summary.trim();

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={e => e.stopPropagation()}>
        <button className="sheet__close" onClick={onClose} aria-label="Close">×</button>
        <div className="sheet__date">New trip</div>
        <h2 className="sheet__title">Propose a trip</h2>
        <div className="sheet__meta">It'll appear in the programme once a leader confirms.</div>

        <div className="form">
          <div className="field">
            <label>Where are we going?</label>
            <input className="input" placeholder="e.g. Mount Brennan via Lyle Creek" value={f.title} onChange={set("title")} />
          </div>
          <div className="field-row">
            <div className="field">
              <label>Date</label>
              <input className="input" type="date" value={f.date} onChange={set("date")} />
            </div>
            <div className="field">
              <label>Meet at</label>
              <input className="input" type="time" value={f.time} onChange={set("time")} />
            </div>
          </div>
          <div className="field-row">
            <div className="field">
              <label>Grade</label>
              <select className="select" value={f.grade} onChange={set("grade")}>
                <option>Easy</option><option>Moderate</option><option>Hard</option>
              </select>
            </div>
            <div className="field">
              <label>Spaces</label>
              <input className="input" type="number" min="1" value={f.capacity} onChange={set("capacity")} />
            </div>
          </div>
          <div className="field">
            <label>Leader</label>
            <input className="input" value={f.leader} onChange={set("leader")} />
          </div>
          <div className="field">
            <label>A line or two about the day</label>
            <textarea className="textarea" placeholder="Pace, terrain, what to bring…" value={f.summary} onChange={set("summary")}></textarea>
          </div>
        </div>

        <div className="sheet__cta" style={{ marginTop: "22px" }}>
          <button className="btn btn--secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn--primary" disabled={!valid} onClick={() => onSubmit(f)}>Add to programme</button>
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { ProposeTrip });
