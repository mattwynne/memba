// Wireframes — line icons (Lucide-style, 1.6 stroke, currentColor)
function WIcon({ name, size = 20, stroke = 1.6 }) {
  const p = { width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round" };
  switch (name) {
    case "send":     return <svg {...p}><path d="M14.5 9.5 21 3m0 0-6.5 18-4-8-8-4L21 3Z"/></svg>;
    case "logout":   return <svg {...p}><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/></svg>;
    case "arrow-l":  return <svg {...p}><path d="m15 18-6-6 6-6"/></svg>;
    case "chev":     return <svg {...p}><path d="m9 6 6 6-6 6"/></svg>;
    case "info":     return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/></svg>;
    case "users":    return <svg {...p}><circle cx="9" cy="8" r="3.4"/><path d="M3 20a6 6 0 0 1 12 0"/><circle cx="17.5" cy="9" r="2.6"/><path d="M15 20a5 5 0 0 1 7.5 0"/></svg>;
    case "mail":     return <svg {...p}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>;
    case "mail-plus":return <svg {...p}><path d="M21 11V7a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h8"/><path d="m3 7 9 6 9-6"/><path d="M19 16v6M16 19h6"/></svg>;
    // status icons (member-facing)
    case "opened":   return <svg {...p}><path d="M21.2 8.5 12 14 2.8 8.5"/><path d="M3 19h18a1 1 0 0 0 1-1V9.2a2 2 0 0 0-.97-1.71l-8-4.8a2 2 0 0 0-2.06 0l-8 4.8A2 2 0 0 0 2 9.2V18a1 1 0 0 0 1 1Z"/><path d="m8 11 4 2.5L16 11"/></svg>;
    case "delivered":return <svg {...p}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m7 10 3.5 3.5L21 5.5"/></svg>;
    case "sending":  return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case "problem":  return <svg {...p}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/><path d="M12 11.5v2.5M12 16.5h.01"/></svg>;
    case "check":    return <svg {...p}><path d="M20 6 9 17l-5-5"/></svg>;
    case "x":        return <svg {...p}><path d="M18 6 6 18M6 6l12 12"/></svg>;
    case "refresh":  return <svg {...p}><path d="M3 12a9 9 0 0 1 15-6.7L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16"/><path d="M3 21v-5h5"/></svg>;
    case "eye-glance": return <svg {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>;
    default: return null;
  }
}
Object.assign(window, { WIcon });
