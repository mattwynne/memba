// Member app — Directory (member list + search) and member detail
function statusPill(status) {
  if (status === "active")   return <span className="pill pill--ok"><span className="dot"></span>Active</span>;
  if (status === "due-soon") return <span className="pill pill--warn"><span className="dot"></span>Renews soon</span>;
  return <span className="pill pill--info"><span className="dot"></span>Lapsed</span>;
}

function DirectoryView({ members, onOpen }) {
  const [q, setQ] = React.useState("");
  const filtered = members
    .filter(m => (m.name + " " + m.town + " " + m.role).toLowerCase().includes(q.toLowerCase()))
    .sort((a, b) => a.last.localeCompare(b.last));

  // group by first letter of surname
  const groups = [];
  filtered.forEach(m => {
    const L = m.last[0].toUpperCase();
    let g = groups.find(x => x.L === L);
    if (!g) { g = { L, items: [] }; groups.push(g); }
    g.items.push(m);
  });

  return (
    <div className="fade-in">
      <div className="field-band">
        <span className="page-eyebrow">{members.length} members</span>
        <h1 className="page-title">Directory</h1>
      </div>

      <div className="search">
        <Icon name="search" size={18} />
        <input placeholder="Search by name, town, or role" value={q} onChange={e => setQ(e.target.value)} />
        {q && <span className="search__count">{filtered.length} found</span>}
      </div>

      {filtered.length === 0 ? (
        <div className="dir-empty">No one matches "{q}".</div>
      ) : (
        groups.map(g => (
          <div key={g.L}>
            <div className="dir-letter">{g.L}</div>
            <div className="dir-list">
              {g.items.map(m => (
                <button className="dir-row" key={m.id} onClick={() => onOpen(m)}>
                  <div className="dir-av" style={{ background: m.av }}>{m.initials}</div>
                  <div>
                    <div className="dir-row__name">{m.name}{m.id === ME.id ? " (you)" : ""}</div>
                    <div className="dir-row__sub">{m.town} · member since {m.since}</div>
                  </div>
                  <span className="dir-row__role">{m.role}</span>
                  <span className="dir-row__chev"><Icon name="chev" size={18} /></span>
                </button>
              ))}
            </div>
          </div>
        ))
      )}
    </div>
  );
}

function MemberDetail({ member, onClose, onMessage }) {
  if (!member) return null;
  const m = member;
  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={e => e.stopPropagation()}>
        <button className="sheet__close" onClick={onClose} aria-label="Close">×</button>
        <div className="sheet__profilehead">
          <div className="dir-av" style={{ background: m.av }}>{m.initials}</div>
          <div>
            <h2 className="sheet__title" style={{ margin: 0 }}>{m.name}</h2>
            <div className="sheet__meta" style={{ marginBottom: 0 }}>{m.role} · {m.town}</div>
          </div>
        </div>

        <div style={{ marginBottom: "8px" }}>{statusPill(m.status)}</div>

        <dl className="sheet__deftable">
          <dt>Member since</dt><dd>{m.since}</dd>
          <dt>Email</dt><dd><a href={"mailto:" + m.email}>{m.email}</a></dd>
          <dt>Phone</dt><dd>{m.phone}</dd>
          <dt>Town</dt><dd>{m.town}, BC</dd>
        </dl>

        <div className="sheet__cta">
          <button className="btn btn--secondary" onClick={onClose}>Close</button>
          <button className="btn btn--primary" onClick={() => onMessage(m)}>
            <Icon name="send" size={17} /> Message {m.first}
          </button>
        </div>
      </div>
    </div>
  );
}
Object.assign(window, { DirectoryView, MemberDetail, statusPill });
