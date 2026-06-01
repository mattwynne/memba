// Marketing site — features (type-only, no illustrations)
function FeatureCard({ kicker, title, body }) {
  return (
    <article className="m-feat">
      <span className="m-feat__kicker">{kicker}</span>
      <h3 className="m-feat__title">{title}</h3>
      <p className="m-feat__body">{body}</p>
    </article>
  );
}

const M_FEATURES = [
  {
    kicker: "01",
    title: "Plan and run events",
    full: "A rehearsal, a regatta, a committee meeting. Members tap once to add themselves. Waitlists, capacity, reminders — handled.",
    tight: "Members add themselves in one tap. Waitlists and reminders, handled.",
  },
  {
    kicker: "02",
    title: "Renewals without chasing",
    full: "Memba sends the reminder, the link, the receipt. You see who's renewed and who's drifted, in one calm list.",
    tight: "Memba sends the reminder and the receipt. You see who's renewed.",
  },
  {
    kicker: "03",
    title: "Notes to your members",
    full: "A message to the whole club, or just to next week's group. Replies thread back to you, not to a 200-strong reply-all.",
    tight: "Message the whole club. Replies come back to you, not a reply-all.",
  },
];

function Features({ tight, count }) {
  const shown = count === "one" ? M_FEATURES.slice(2, 3) : M_FEATURES;
  const heading = count === "one" ? "One thing, done quietly." : "Three things, done quietly.";
  return (
    <section className="m-section" id="features">
      <div className="m-section__head">
        <span className="eyebrow">Product</span>
        <h2>{heading}</h2>
      </div>
      <div className={`m-feats ${count === "one" ? "m-feats--single" : ""}`}>
        {shown.map((f) => (
          <FeatureCard key={f.kicker} kicker={f.kicker} title={f.title} body={tight ? f.tight : f.full} />
        ))}
      </div>
    </section>
  );
}

Object.assign(window, { Features });
