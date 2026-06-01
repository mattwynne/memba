// Member app — shell with collapsible-style left rail (iPad)
function AppShell({ view, setView, children }) {
  const items = [
    { id: "home",      label: "Home",       icon: "home" },
    { id: "trips",     label: "Trips",      icon: "mountain" },
    { id: "directory", label: "Directory",  icon: "users" },
    { id: "messages",  label: "Messages",   icon: "message" },
    { id: "profile",   label: "Membership", icon: "user" },
  ];
  return (
    <aside className="rail">
      <div className="rail__brand">
        <svg className="rail__brandmark" width="30" height="30" viewBox="0 0 64 64">
          <path d="M32 51 C32 43 32 36 32 18" fill="none" stroke="#5a7050" strokeWidth="3" strokeLinecap="round"/>
          <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="none" stroke="#5a7050" strokeWidth="2.6" strokeLinejoin="round"/>
          <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="none" stroke="#5a7050" strokeWidth="2.6" strokeLinejoin="round"/>
          <circle cx="32" cy="15" r="3" fill="#d2925a"/>
        </svg>
        <span className="name">memba</span>
      </div>
      <div className="rail__group">Kootenay Mountaineering</div>
      {items.map(it => (
        <button
          key={it.id}
          className={`rail__item ${view === it.id ? "is-active" : ""}`}
          onClick={() => setView(it.id)}
        >
          <Icon name={it.icon} size={20} />
          <span>{it.label}</span>
          {it.id === "messages" && <span className="rail__badge">2</span>}
        </button>
      ))}
      <div className="rail__spacer"></div>
      <div className="rail__me">
        <div className="av">{ME.initials}</div>
        <div>
          <div className="who">{ME.name}</div>
          <div className="sub">{ME.role}</div>
        </div>
      </div>
    </aside>
  );
}
Object.assign(window, { AppShell });
