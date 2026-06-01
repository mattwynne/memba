// ============================================================
// 3 · Message Detail / Member Receipts
// ============================================================
const STATUS = {
  opened:  { label: "Opened",           icon: "opened",    st: "st-opened",  tint: "tint-opened",  bg: "bg-opened",  count: 24, pct: 57, desc: "Read it" },
  deliv:   { label: "Delivered",        icon: "delivered", st: "st-deliv",   tint: "tint-deliv",   bg: "bg-deliv",   count: 14, pct: 33, desc: "Arrived, not opened yet" },
  sending: { label: "Sending",          icon: "sending",   st: "st-sending", tint: "tint-sending", bg: "bg-sending", count: 2,  pct: 5,  desc: "On its way" },
  problem: { label: "Delivery problem",  icon: "problem",   st: "st-problem", tint: "tint-problem", bg: "bg-problem", count: 2,  pct: 5,  desc: "We couldn't reach them" },
};

const RECIPIENTS = {
  problem: [
    { name: "Carol Whitfield", initials: "CW", colour: "#e8c7a8", note: "We'll keep trying" },
    { name: "Tom Bridger",     initials: "TB", colour: "#e8c7a8", note: "We'll keep trying" },
  ],
  sending: [
    { name: "Alice Renner",    initials: "AR", colour: "#cdd6d1", note: "Just now" },
    { name: "Sam Okafor",      initials: "SO", colour: "#cdd6d1", note: "Just now" },
  ],
  deliv: [
    { name: "Bob Calloway",    initials: "BC", colour: "#a6c0b1", note: "9:15am" },
    { name: "Priya Dholakia",  initials: "PD", colour: "#7aa08c", note: "9:14am" },
    { name: "Eira Sandhu",     initials: "ES", colour: "#a6c0b1", note: "9:14am" },
  ],
  opened: [],
};

function GroupRow({ k, open, onToggle }) {
  const s = STATUS[k];
  const rows = RECIPIENTS[k] || [];
  const hidden = s.count - rows.length;
  return (
    <div className={"group" + (open ? " is-open" : "")}>
      <button className="group__head" onClick={onToggle}>
        <div className={"group__statusicon " + s.tint + " " + s.st}><WIcon name={s.icon} size={17} /></div>
        <div>
          <div className="group__label">{s.label}</div>
          <div className="group__desc">{s.desc}</div>
        </div>
        <div className="group__count">{s.count}</div>
        <span className="group__chev"><WIcon name="chev" size={16} /></span>
      </button>
      {open && (
        <div className="group__body">
          {rows.map((r, i) => (
            <div key={i} className="recipient">
              <div className="av av--sm" style={{ background: r.colour }}>{r.initials}</div>
              <div className="recipient__name">{r.name}</div>
              <span className={"recipient__status " + s.st}><WIcon name={s.icon} size={15} />{s.label}</span>
              <span className="recipient__time">{r.note}</span>
            </div>
          ))}
          {hidden > 0 && (
            <div className="recipient" style={{ justifyContent: "center" }}>
              <button className="section__link">Show {hidden} more</button>
            </div>
          )}
          {rows.length === 0 && (
            <div className="recipient" style={{ justifyContent: "center" }}>
              <button className="section__link">Show {s.count} members</button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Receipts() {
  const [open, setOpen] = React.useState({ problem: true, sending: true, deliv: true, opened: false });
  const toggle = (k) => setOpen(o => ({ ...o, [k]: !o[k] }));
  const order = ["opened", "deliv", "sending", "problem"];

  return (
    <ScreenFrame>
      <a className="back" href="#"><WIcon name="arrow-l" size={15} />Club home</a>
      <span className="eyebrow">Club message</span>
      <h1 className="h-page">AGM is on Sat 22 Sept — tea provided</h1>
      <p className="lede" style={{ marginTop: "12px", fontSize: "14px", color: "var(--fg3)" }}>
        From Eira Sandhu · Sent Sat 8 Sept, 9:14am · to 42 members
      </p>

      <p className="msg-detail__body">
        Just a reminder that this year's AGM is at the clubroom from 2pm. We'll be voting on next
        year's trip programme and the membership-fee review. Tea, biscuits, the usual. Do come — it's
        your club, and the more voices the better.
      </p>

      {/* summary */}
      <div className="receipt-summary">
        <div className="section__title" style={{ marginBottom: "14px" }}><WIcon name="users" size={17} />Who got this</div>
        <div className="bar">
          {order.map(k => <span key={k} className={STATUS[k].bg} style={{ width: STATUS[k].pct + "%" }}></span>)}
        </div>
        <div className="bar-legend">
          {order.map(k => (
            <div key={k} className="legend-item">
              <span className={"legend-dot " + STATUS[k].bg}></span>
              <span className="legend-item__txt"><strong>{STATUS[k].label}</strong></span>
              <span className="legend-item__num">{STATUS[k].count}</span>
              <span className="legend-item__pct">{STATUS[k].pct}%</span>
            </div>
          ))}
        </div>
      </div>

      {/* grouped breakdown */}
      <div className="section__head" style={{ marginTop: "30px", marginBottom: "2px" }}>
        <div className="section__title">Everyone, by status</div>
        <button className="section__link">Collapse all</button>
      </div>
      <div className="groups">
        {order.map(k => <GroupRow key={k} k={k} open={open[k]} onToggle={() => toggle(k)} />)}
      </div>
    </ScreenFrame>
  );
}

Object.assign(window, { Receipts, GroupRow });
