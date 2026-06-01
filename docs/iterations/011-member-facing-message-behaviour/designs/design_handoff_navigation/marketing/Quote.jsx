// Marketing site — quote (no italic, no avatar bubble)
function Quote() {
  return (
    <section className="m-section m-quote" id="story">
      <figure>
        <blockquote>
          “We used to chase renewals on a paper sheet pinned to the rehearsal-room door. With Memba, everyone's signed up by the first concert.”
        </blockquote>
        <figcaption>
          <strong>Priya Dholakia</strong>
          <span className="meta">Secretary, Kootenay Mountaineering Club · 198 members</span>
        </figcaption>
      </figure>
    </section>
  );
}

Object.assign(window, { Quote });
