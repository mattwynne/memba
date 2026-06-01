// Member app — Messages: inbox, compose (committee), delivery tracking
function MessagesView({ messages, onCompose, onDelivery }) {
  return (
    <div className="fade-in">
      <div className="field-band">
        <div className="page-head">
          <div>
            <span className="page-eyebrow">From the committee</span>
            <h1 className="page-title">Messages</h1>
          </div>
          {ME.committee && (
            <div className="page-head__actions">
              <button className="btn btn--primary" onClick={() => onCompose(null)}>
                <Icon name="send" size={17} /> Write a message
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="msg-list">
        {messages.map(m => (
          <div key={m.id} className={`msg ${m.kind === "broadcast" ? "is-broadcast" : ""}`}>
            <div className="av" style={{ background: m.colour }}>{m.initials}</div>
            <div>
              <div className="msg__head">
                <span className="msg__who">{m.who}{m.kind === "broadcast" && <span className="msg__tag">Broadcast</span>}</span>
                <span className="msg__when">{m.when}</span>
              </div>
              <div className="msg__subject">{m.subject}</div>
              <div className="msg__body">{m.body}</div>

              {m.kind === "broadcast" && m.stats && (
                <div className="msg__stats">
                  <span className="msg__stat"><b>{m.stats.sent}</b> sent</span>
                  <span className="msg__stat"><b>{m.stats.opened}</b> opened</span>
                  {m.stats.bounced > 0 && <span className="msg__stat" style={{ color: "var(--danger)" }}><b style={{ color: "var(--danger)" }}>{m.stats.bounced}</b> bounced</span>}
                  {ME.committee && (
                    <button className="btn btn--ghost msg__statlink" style={{ minHeight: "auto", padding: "4px 10px" }} onClick={() => onDelivery(m)}>
                      View delivery →
                    </button>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ---- Compose ----
function ComposeSheet({ open, presetMember, onClose, onSend }) {
  if (!open) return null;
  const [aud, setAud] = React.useState(presetMember ? "one" : "all");
  const [subject, setSubject] = React.useState("");
  const [body, setBody] = React.useState("");
  const options = [
    { id: "all",   label: "All members",       sub: "Everyone with an active membership", n: "198 people" },
    { id: "trip",  label: "A trip roster",     sub: "Just the people on one trip",         n: "Kokanee · 6" },
    { id: "one",   label: presetMember ? presetMember.name : "One member", sub: "A single person", n: presetMember ? presetMember.town : "Pick someone" },
  ];
  const valid = subject.trim() && body.trim();

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={e => e.stopPropagation()}>
        <button className="sheet__close" onClick={onClose} aria-label="Close">×</button>
        <div className="sheet__date">New message</div>
        <h2 className="sheet__title">Write a message</h2>
        <div className="sheet__meta">Plain text, sent by email. Members reply to your address.</div>

        <div className="form">
          <div className="field">
            <label>Who's it for?</label>
            <div className="audience">
              {options.map(o => (
                <div key={o.id} className={`aud-opt ${aud === o.id ? "is-on" : ""}`} onClick={() => setAud(o.id)}>
                  <span className="aud-opt__radio"></span>
                  <div>
                    <div className="aud-opt__label">{o.label}</div>
                    <div className="aud-opt__sub">{o.sub}</div>
                  </div>
                  <span className="aud-opt__n">{o.n}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="field">
            <label>Subject</label>
            <input className="input" placeholder="Keep it short and plain" value={subject} onChange={e => setSubject(e.target.value)} />
          </div>
          <div className="field">
            <label>Message</label>
            <textarea className="textarea" style={{ minHeight: "140px" }} placeholder="Write as you'd speak at the club hut…" value={body} onChange={e => setBody(e.target.value)}></textarea>
          </div>
        </div>

        <div className="sheet__cta" style={{ marginTop: "22px" }}>
          <button className="btn btn--secondary" onClick={onClose}>Cancel</button>
          <button className="btn btn--primary" disabled={!valid} onClick={() => onSend(options.find(o => o.id === aud))}>
            <Icon name="send" size={17} /> Send it
          </button>
        </div>
      </div>
    </div>
  );
}

// ---- Delivery tracking ----
function DeliverySheet({ message, onClose }) {
  if (!message) return null;
  const s = message.stats;
  const pending = Math.max(0, s.sent - s.delivered - s.bounced);
  const seg = [
    ["var(--success)", s.opened],
    ["var(--info)", s.delivered - s.opened],
    ["var(--danger)", s.bounced],
    ["var(--warning)", s.spam],
    ["var(--line-strong)", pending],
  ];
  const recips = message.recipients.map(r => ({ ...r, m: MEMBERS.find(x => x.id === r.id) })).filter(r => r.m);
  const label = { opened: "Opened", delivered: "Delivered", bounced: "Bounced", spam: "Spam", pending: "Pending" };

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet" onClick={e => e.stopPropagation()} style={{ width: "min(640px, 94vw)" }}>
        <button className="sheet__close" onClick={onClose} aria-label="Close">×</button>
        <div className="sheet__date">Delivery · {message.audience}</div>
        <h2 className="sheet__title" style={{ fontSize: "26px" }}>{message.subject}</h2>
        <div className="sheet__meta">Sent by {message.who} · {message.when}</div>

        <div className="deliv-summary">
          <div className="deliv-stat"><div className="n">{s.sent}</div><div className="k">Sent</div></div>
          <div className="deliv-stat"><div className="n">{s.opened}</div><div className="k">Opened</div></div>
          <div className={`deliv-stat ${s.bounced ? "is-danger" : ""}`}><div className="n">{s.bounced}</div><div className="k">Bounced</div></div>
          <div className={`deliv-stat ${s.spam ? "is-warn" : ""}`}><div className="n">{s.spam}</div><div className="k">Spam</div></div>
        </div>

        <div className="deliv-bar">
          {seg.map(([c, n], i) => n > 0 && <span key={i} style={{ background: c, flex: n }}></span>)}
        </div>

        <div className="card__eyebrow" style={{ marginBottom: "8px" }}>Recent activity</div>
        <div className="recip-list">
          {recips.map(r => (
            <div className="recip-row" key={r.id}>
              <div className="av" style={{ background: r.m.av }}>{r.m.initials}</div>
              <div>
                <div className="recip-row__who">{r.m.name}</div>
                <div className="recip-row__addr">{r.m.email}</div>
              </div>
              <span className={`dstat dstat--${r.status}`}>
                <span className="dot"></span>{label[r.status] || r.status}
              </span>
            </div>
          ))}
        </div>
        {s.bounced > 0 && (
          <p className="card__meta" style={{ marginTop: "14px" }}>
            <Icon name="alert" size={14} /> {s.bounced} address{s.bounced > 1 ? "es" : ""} bounced — Memba will retry, then flag them for you to chase.
          </p>
        )}
      </div>
    </div>
  );
}
Object.assign(window, { MessagesView, ComposeSheet, DeliverySheet });
