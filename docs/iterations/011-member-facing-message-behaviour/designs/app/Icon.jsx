// Member app — inline single-weight icons (Lucide-style, 1.6px stroke)
function Icon({ name, size = 20, stroke = 1.6 }) {
  const p = { width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round" };
  switch (name) {
    case "home":    return <svg {...p}><path d="M3 12 12 3l9 9"/><path d="M5 10v10h14V10"/></svg>;
    case "events":  return <svg {...p}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/></svg>;
    case "mountain":return <svg {...p}><path d="m3 20 6.5-11 4 6 2.5-4L21 20Z"/></svg>;
    case "message": return <svg {...p}><path d="M21 12a8 8 0 0 1-8 8 9 9 0 0 1-3-.5L4 21l1.5-6A8 8 0 1 1 21 12Z"/></svg>;
    case "user":    return <svg {...p}><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>;
    case "users":   return <svg {...p}><circle cx="9" cy="8" r="3.5"/><path d="M3 21a6 6 0 0 1 12 0"/><circle cx="17" cy="9" r="2.8"/><path d="M14.5 21a5 5 0 0 1 8 0"/></svg>;
    case "check":   return <svg {...p}><path d="m5 12 5 5 9-11"/></svg>;
    case "card":    return <svg {...p}><rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18"/></svg>;
    case "chev":    return <svg {...p}><path d="m9 6 6 6-6 6"/></svg>;
    case "search":  return <svg {...p}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>;
    case "plus":    return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
    case "send":    return <svg {...p}><path d="M22 2 11 13"/><path d="M22 2 15 22l-4-9-9-4Z"/></svg>;
    case "mail":    return <svg {...p}><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>;
    case "back":    return <svg {...p}><path d="M19 12H5"/><path d="m12 19-7-7 7-7"/></svg>;
    case "pin":     return <svg {...p}><path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11Z"/><circle cx="12" cy="10" r="2.5"/></svg>;
    case "clock":   return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case "eye":     return <svg {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>;
    case "alert":   return <svg {...p}><path d="M12 9v4M12 17h.01"/><path d="M10.3 3.8 2.4 18a2 2 0 0 0 1.7 3h15.8a2 2 0 0 0 1.7-3L13.7 3.8a2 2 0 0 0-3.4 0Z"/></svg>;
    case "x":       return <svg {...p}><path d="M18 6 6 18M6 6l12 12"/></svg>;
    case "compass": return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2 5-5 2 2-5 5-2Z"/></svg>;
    case "phone":   return <svg {...p}><path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L20 12l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2Z"/></svg>;
    case "flag":    return <svg {...p}><path d="M4 21V4M4 4h11l-1.5 3L15 10H4"/></svg>;
    default: return null;
  }
}
Object.assign(window, { Icon });
