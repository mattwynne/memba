// Marketing site — sign-up modal
function SignupModal({ open, onClose }) {
  const [step, setStep] = React.useState(0);
  const [clubName, setClubName] = React.useState("");
  if (!open) return null;
  return (
    <div className="m-modal__backdrop" onClick={onClose}>
      <div className="m-modal" onClick={e => e.stopPropagation()}>
        <button className="m-modal__close" onClick={onClose} aria-label="Close">×</button>
        {step === 0 && (
          <>
            <span className="eyebrow">Get started</span>
            <h2>Tell us your club's name.</h2>
            <p className="m-modal__lede">We'll set up a tidy little space, no card needed.</p>
            <label className="m-field">
              <span>Club name</span>
              <input
                type="text"
                placeholder="e.g. West Kootenay Alpine Club"
                value={clubName}
                onChange={e => setClubName(e.target.value)}
                autoFocus
              />
            </label>
            <button
              className="btn btn--primary btn--lg"
              disabled={!clubName.trim()}
              onClick={() => setStep(1)}
            >
              Next
            </button>
          </>
        )}
        {step === 1 && (
          <>
            <span className="eyebrow">Almost there</span>
            <h2>Welcome, {clubName}.</h2>
            <p className="m-modal__lede">We'll email you a link to set a password — no need to remember another one.</p>
            <label className="m-field">
              <span>Your email</span>
              <input type="email" placeholder="you@yourclub.org" autoFocus />
            </label>
            <button className="btn btn--primary btn--lg" onClick={() => setStep(2)}>Send me the link</button>
          </>
        )}
        {step === 2 && (
          <>
            <div className="m-modal__check">✓</div>
            <h2>Check your inbox.</h2>
            <p className="m-modal__lede">We sent a link. It expires in an hour. Welcome to Memba.</p>
            <button className="btn btn--secondary" onClick={onClose}>Close</button>
          </>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { SignupModal });
