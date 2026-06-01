// ============================================================
// Shared white-label club chrome
// ============================================================
function Chrome() {
  return (
    <header className="chrome">
      <div className="chrome__brand">
        <div className="chrome__mark">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f7f6f3" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 18 9 7l4 6 2-3 5 8z"/>
          </svg>
        </div>
        <div>
          <div className="chrome__club">Kootenay Alpine Club</div>
          <div className="chrome__sub">Members</div>
        </div>
      </div>
      <div className="chrome__me">
        <div className="chrome__id">
          <div className="chrome__av">LT</div>
          <div className="chrome__name">Lou Thirgood</div>
        </div>
        <button className="chrome__signout"><WIcon name="logout" size={16} />Sign out</button>
      </div>
    </header>
  );
}

function ScreenFrame({ children }) {
  return (
    <div className="screen">
      <Chrome />
      <div className="screen__scroll">
        <div className="measure">{children}</div>
      </div>
      <footer className="screen__foot">
        Powered by <span className="pb">Memba</span>
      </footer>
    </div>
  );
}

// ============================================================
// 1 · Club Home / Member Dashboard
// ============================================================
const HOME_MESSAGES = [
  { id: 1, who: "Eira Sandhu", initials: "ES", colour: "#a6c0b1", when: "2 days ago",
    subject: "AGM is on Sat 22 Sept — tea provided",
    seg: [[57, "bg-opened"], [33, "bg-deliv"], [5, "bg-sending"], [5, "bg-problem"]], glance: "24 of 42 opened" },
  { id: 2, who: "Priya Dholakia", initials: "PD", colour: "#7aa08c", when: "1 week ago",
    subject: "Choir rehearsal Tuesdays through October",
    seg: [[88, "bg-opened"], [12, "bg-deliv"]], glance: "37 of 42 opened" },
  { id: 3, who: "You", initials: "LT", colour: "#d2e0d7", when: "3 weeks ago",
    subject: "Boat shed clear-out — Sunday morning",
    seg: [[71, "bg-opened"], [21, "bg-deliv"], [8, "bg-problem"]], glance: "30 of 42 opened" },
];

function MsgRow({ m }) {
  return (
    <div className="msg-row">
      <div className="av" style={{ background: m.colour }}>{m.initials}</div>
      <div>
        <div className="msg-row__who">{m.who}</div>
        <div className="msg-row__subject">{m.subject}</div>
        <div className="msg-row__glance">
          <span className="mini-bar">
            {m.seg.map((s, i) => <span key={i} className={s[1]} style={{ width: s[0] + "%" }}></span>)}
          </span>
          {m.glance}
        </div>
      </div>
      <div className="msg-row__when">{m.when}</div>
    </div>
  );
}

function Dashboard() {
  const members = [
    ["LT", "#d2e0d7"], ["ES", "#a6c0b1"], ["PD", "#7aa08c"], ["BG", "#c9ddd0"],
    ["CV", "#bcd0c3"], ["NK", "#aec7b8"],
  ];
  return (
    <ScreenFrame>
      <span className="eyebrow">Kootenay Alpine Club</span>
      <h1 className="h-page">Hello, Lou.</h1>
      <p className="lede">What the club's been saying, and who's around right now.</p>

      <div className="cta-card">
        <div className="cta-card__txt">
          <h3>Got something to share?</h3>
          <p>Write once — every active member gets it.</p>
        </div>
        <button className="btn btn--primary"><WIcon name="send" size={18} />Send club message</button>
      </div>

      <div className="section">
        <div className="section__head">
          <div className="section__title"><WIcon name="mail" size={17} />Recent club messages</div>
          <button className="section__link">See all</button>
        </div>
        <div className="list">
          {HOME_MESSAGES.map(m => <MsgRow key={m.id} m={m} />)}
        </div>
      </div>

      <div className="section">
        <div className="section__head">
          <div className="section__title"><WIcon name="users" size={17} />Active members</div>
          <button className="section__link">View all 42</button>
        </div>
        <div className="members-card">
          <div className="av-stack">
            {members.map((a, i) => <div key={i} className="av" style={{ background: a[1] }}>{a[0]}</div>)}
            <div className="av-more">+36</div>
          </div>
          <div className="members-card__txt">
            <strong>42 active members</strong>
            <p>Everyone with a current membership. They'll all receive your messages.</p>
          </div>
        </div>
      </div>
    </ScreenFrame>
  );
}

// ---------- Dashboard · empty state ----------
function DashboardEmpty() {
  return (
    <ScreenFrame>
      <span className="eyebrow">Kootenay Alpine Club</span>
      <h1 className="h-page">Hello, Lou.</h1>
      <p className="lede">What the club's been saying, and who's around right now.</p>

      <div className="cta-card">
        <div className="cta-card__txt">
          <h3>Got something to share?</h3>
          <p>Write once — every active member gets it.</p>
        </div>
        <button className="btn btn--primary"><WIcon name="send" size={18} />Send club message</button>
      </div>

      <div className="section">
        <div className="section__head">
          <div className="section__title"><WIcon name="mail" size={17} />Recent club messages</div>
        </div>
        <div className="empty">
          <div className="empty__icon"><WIcon name="mail" size={22} /></div>
          <div className="empty__title">No messages yet</div>
          <div className="empty__sub">When someone sends a note to the club, it'll show up here.</div>
          <button className="btn btn--secondary"><WIcon name="send" size={16} />Send the first one</button>
        </div>
      </div>

      <div className="section">
        <div className="section__head">
          <div className="section__title"><WIcon name="users" size={17} />Active members</div>
        </div>
        <div className="empty">
          <div className="empty__icon"><WIcon name="users" size={22} /></div>
          <div className="empty__title">You're the first one here</div>
          <div className="empty__sub">As members join and renew, you'll see them listed here.</div>
        </div>
      </div>
    </ScreenFrame>
  );
}

Object.assign(window, { Chrome, ScreenFrame, Dashboard, DashboardEmpty, MsgRow });
