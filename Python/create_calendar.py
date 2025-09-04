import uuid
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
from icalendar import Calendar, Event, vText

# --- config -----------------------------------------------------------------
CSV_PATH = "../data/AY25-26_sem_1_timetable.csv"
ICS_OUT = Path("calendar/macsi-seminar-series-calendar.ics")

# --- helpers ----------------------------------------------------------------
def ics_escape(text: str) -> str:
    """Escape characters per RFC 5545."""
    return (
        text.replace("\\", "\\\\")
            .replace("\n", "\\n")
            .replace(",", "\\,")
            .replace(";", "\\;")
    )

def parse_12h_time(date_val, time_str: str):
    """Return naive datetime (floating local time, no TZID)."""
    # Parse date safely
    if isinstance(date_val, str):
        d = pd.to_datetime(date_val).date()
    elif isinstance(date_val, pd.Timestamp):
        d = date_val.date()
    elif isinstance(date_val, datetime):
        d = date_val.date()
    else:
        raise ValueError(f"Unsupported date format: {date_val}")

    # Parse time like '4pm', '11am', '11 am'
    t_str = time_str.strip().lower().replace(" ", "")
    t = datetime.strptime(t_str, "%I%p").time()
    return datetime.combine(d, t)  # <-- no timezone info

# --- load data --------------------------------------------------------------
df = pd.read_csv(CSV_PATH)
df["date"] = pd.to_datetime(df["date"], errors="raise")

now_utc = datetime.utcnow()

# --- build calendar ---------------------------------------------------------
cal = Calendar()
cal.add("prodid", "-//MACSI Seminar Series//AY25-26 Semester 1//EN")
cal.add("version", "2.0")
cal.add("calscale", "GREGORIAN")
cal.add("method", "PUBLISH")

for _, row in df.iterrows():
    start = parse_12h_time(row["date"], row["time"])
    end = start + timedelta(hours=1)

    summary_raw = f"MACSI Seminar: Week no {row['week_no']} given by {row['presenter']}"
    summary = ics_escape(" ".join(summary_raw.split()))

    desc_raw = "See seminar schedule and abstracts at https://macsi-seminars.github.io/"
    desc = ics_escape(" ".join(desc_raw.split()))

    ev = Event()
    ev.add("uid", str(uuid.uuid5(uuid.NAMESPACE_URL, f'{start.isoformat()}|{summary_raw}')))
    ev.add("dtstamp", now_utc)
    ev.add("dtstart", start)  # <- naive datetime = floating time
    ev.add("dtend", end)
    ev.add("summary", vText(summary))
    ev.add("description", vText(desc))
    ev.add("url", "https://macsi-seminars.github.io/")
    cal.add_component(ev)

# --- write out safely -------------------------------------------------------
ics_bytes = cal.to_ical()  # already folded and CRLF-terminated
ICS_OUT.parent.mkdir(parents=True, exist_ok=True)
ICS_OUT.write_bytes(ics_bytes)

print(f"Wrote floating-time ICS to: {ICS_OUT.resolve()}")
