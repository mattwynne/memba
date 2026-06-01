// ============================================================
// 2 · Compose Club Message
// ============================================================
function Compose() {
  return (
    <ScreenFrame>
      <a className="back" href="#"><WIcon name="arrow-l" size={15} />Club home</a>
      <span className="eyebrow">New message</span>
      <h1 className="h-page">Send a club message</h1>

      <div className="note">
        <span className="note__icon"><WIcon name="users" size={18} /></span>
        <span className="note__txt">
          This goes to <strong>all 42 active members</strong> of Kootenay Alpine Club. There's no list to pick — everyone with a current membership gets it.
        </span>
      </div>

      <div className="field">
        <label className="field__label">From</label>
        <div className="select-row">
          <div className="av av--sm" style={{ background: "#d2e0d7" }}>LT</div>
          <div className="select-row__txt">
            <strong>Lou Thirgood (you)</strong>
            <span>Sending as yourself</span>
          </div>
          <WIcon name="chev" size={16} stroke={2} />
        </div>
        <span className="field__hint" style={{ display: "block", marginTop: "7px" }}>You can send on behalf of another active member if you organise together.</span>
      </div>

      <div className="field">
        <label className="field__label">Subject</label>
        <input className="input" type="text" defaultValue="" placeholder="What's this about?" />
      </div>

      <div className="field">
        <label className="field__label">Message</label>
        <textarea className="textarea" placeholder="Write your note to the club…"></textarea>
      </div>

      <div className="form-actions">
        <button className="btn btn--primary btn--lg"><WIcon name="send" size={18} />Send to all members</button>
        <button className="btn btn--secondary btn--lg">Cancel</button>
      </div>
    </ScreenFrame>
  );
}

// ---------- Compose · success ----------
function ComposeSuccess() {
  return (
    <ScreenFrame>
      <div className="state">
        <div className="state__icon state__icon--ok"><WIcon name="check" size={30} stroke={2} /></div>
        <div className="state__title">Message sent.</div>
        <div className="state__sub">Your note is on its way to all 42 active members. You can watch it land on the message page.</div>
        <div className="state__actions">
          <button className="btn btn--primary"><WIcon name="eye-glance" size={17} />See who got it</button>
          <button className="btn btn--secondary">Back to home</button>
        </div>
      </div>
    </ScreenFrame>
  );
}

// ---------- Compose · error ----------
function ComposeError() {
  return (
    <ScreenFrame>
      <div className="state">
        <div className="state__icon state__icon--err"><WIcon name="problem" size={28} /></div>
        <div className="state__title">That didn't send.</div>
        <div className="state__sub">Something went wrong on our end — your message wasn't sent to anyone. We've kept it as a draft, so nothing's lost. Try once more?</div>
        <div className="state__actions">
          <button className="btn btn--primary"><WIcon name="refresh" size={17} />Try again</button>
          <button className="btn btn--secondary">Keep as draft</button>
        </div>
      </div>
    </ScreenFrame>
  );
}

Object.assign(window, { Compose, ComposeSuccess, ComposeError });
