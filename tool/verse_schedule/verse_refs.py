"""Parsing + normalisation helpers for German Bible references and verse texts.

Used by build_pool.py to turn the historic `verse_of_the_day` rows into a
clean, de-duplicated verse pool. Two pool entries are considered the SAME
verse if their references overlap (same book/chapter and at least one shared
verse number) OR their normalised texts are identical.
"""

from __future__ import annotations

import html
import re
import unicodedata
from dataclasses import dataclass

# Canonical (Schlachter-style) book names, keyed by a loose lookup key.
_BOOKS = [
    ("1. Mose", ["1mose", "genesis", "1mo"]),
    ("2. Mose", ["2mose", "exodus", "2mo"]),
    ("3. Mose", ["3mose", "levitikus", "3mo"]),
    ("4. Mose", ["4mose", "numeri", "4mo"]),
    ("5. Mose", ["5mose", "deuteronomium", "5mo"]),
    ("Josua", ["josua"]),
    ("Richter", ["richter"]),
    ("Ruth", ["ruth", "rut"]),
    ("1. Samuel", ["1samuel"]),
    ("2. Samuel", ["2samuel"]),
    ("1. Könige", ["1könige", "1koenige"]),
    ("2. Könige", ["2könige", "2koenige"]),
    ("1. Chronik", ["1chronik"]),
    ("2. Chronik", ["2chronik"]),
    ("Esra", ["esra"]),
    ("Nehemia", ["nehemia"]),
    ("Esther", ["esther", "ester"]),
    ("Hiob", ["hiob", "ijob"]),
    ("Psalm", ["psalm", "psalmen", "ps"]),
    ("Sprüche", ["sprüche", "sprueche", "spr"]),
    ("Prediger", ["prediger", "kohelet"]),
    ("Hohelied", ["hohelied"]),
    ("Jesaja", ["jesaja"]),
    ("Jeremia", ["jeremia"]),
    ("Klagelieder", ["klagelieder"]),
    ("Hesekiel", ["hesekiel", "ezechiel"]),
    ("Daniel", ["daniel"]),
    ("Hosea", ["hosea"]),
    ("Joel", ["joel"]),
    ("Amos", ["amos"]),
    ("Obadja", ["obadja"]),
    ("Jona", ["jona"]),
    ("Micha", ["micha"]),
    ("Nahum", ["nahum"]),
    ("Habakuk", ["habakuk"]),
    ("Zephanja", ["zephanja", "zefanja"]),
    ("Haggai", ["haggai"]),
    ("Sacharja", ["sacharja"]),
    ("Maleachi", ["maleachi"]),
    ("Matthäus", ["matthäus", "matthaeus", "mt"]),
    ("Markus", ["markus", "mk"]),
    ("Lukas", ["lukas", "lk"]),
    ("Johannes", ["johannes", "johannas", "joh"]),
    ("Apostelgeschichte", ["apostelgeschichte", "apg"]),
    ("Römer", ["römer", "roemer", "römerbrief", "röm"]),
    ("1. Korinther", ["1korinther", "1korinter", "1korintherbrief", "1kor"]),
    ("2. Korinther", ["2korinther", "2korinter", "2korintherbrief", "2kor"]),
    ("Galater", ["galater", "galaterbrief", "gal"]),
    ("Epheser", ["epheser", "epheserbrief", "eph"]),
    ("Philipper", ["philipper", "philipperbrief", "phil"]),
    ("Kolosser", ["kolosser", "kollosser", "kolosserbrief", "kol"]),
    ("1. Thessalonicher", ["1thessalonicher", "1thess"]),
    ("2. Thessalonicher", ["2thessalonicher", "2thess"]),
    ("1. Timotheus", ["1timotheus", "1timothäus", "1tim"]),
    ("2. Timotheus", ["2timotheus", "2timothäus", "2tim"]),
    ("Titus", ["titus", "titusbrief"]),
    ("Philemon", ["philemon"]),
    ("Hebräer", ["hebräer", "hebraeer", "hebräerbrief", "hebr", "heb"]),
    ("Jakobus", ["jakobus", "jakobusbrief", "jak"]),
    ("1. Petrus", ["1petrus", "1petrusbrief", "1petr"]),
    ("2. Petrus", ["2petrus", "2petrusbrief", "2petr"]),
    ("1. Johannes", ["1johannes", "1johannesbrief", "1joh"]),
    ("2. Johannes", ["2johannes", "2joh"]),
    ("3. Johannes", ["3johannes", "3joh"]),
    ("Judas", ["judas", "judasbrief"]),
    ("Offenbarung", ["offenbarung", "offb"]),
]
_BOOK_LOOKUP = {alias: name for name, aliases in _BOOKS for alias in aliases}
# Books with a single chapter: "Judas 20" means chapter 1, verse 20.
_SINGLE_CHAPTER = {"Judas", "Obadja", "Philemon", "2. Johannes", "3. Johannes"}

_INVISIBLE = re.compile(r"[​-‏‪-‮⁠﻿]")


def clean_text(value: str) -> str:
    """HTML entities/tags, invisible chars and whitespace cleanup."""
    value = html.unescape(value or "")
    value = re.sub(r"<[^>]+>", " ", value)
    value = _INVISIBLE.sub("", value)
    value = value.replace("\xa0", " ")
    value = re.sub(r"\s+", " ", value).strip()
    return value


# Pre-1996 orthography in some historic rows -> current Schlachter 2000 spelling.
_SPELLING = [
    ("daß", "dass"), ("Daß", "Dass"), ("muß", "muss"), ("mußt", "musst"),
    ("mußte", "musste"), ("läßt", "lässt"), ("laßt", "lasst"), ("Laßt", "Lasst"),
    ("faßt", "fasst"), ("wißt", "wisst"), ("Wißt", "Wisst"), ("Haß", "Hass"),
    ("gewiß", "gewiss"), ("Schluß", "Schluss"), ("Fluß", "Fluss"), ("ißt", "isst"),
    ("vergißt", "vergisst"), ("Vergiß", "Vergiss"), ("vergiß", "vergiss"),
    ("Unterlaß", "Unterlass"), ("unablässig", "unablässig"),
    ("Mißt", "Misst"), ("mißt", "misst"), ("Gewißheit", "Gewissheit"),
    ("bewußt", "bewusst"), ("Bewußt", "Bewusst"),
    ("Kuß", "Kuss"), ("Genuß", "Genuss"), ("Entschluß", "Entschluss"),
    ("Ratschluß", "Ratschluss"), ("Überfluß", "Überfluss"), ("Einfluß", "Einfluss"),
    ("Ausfluß", "Ausfluss"), ("Anlaß", "Anlass"), ("Ablaß", "Ablass"),
    ("Mißgunst", "Missgunst"), ("wäßrig", "wässrig"),
]


def clean_verse(value: str) -> str:
    """Display text: Schlachter's [inserted words] lose their brackets,
    surrounding quote marks are removed (the image adds its own)."""
    value = clean_text(value)
    value = re.sub(r"\[([^\]]*)\]", r"\1", value)
    value = re.sub(r"\s+([,.;:!?])", r"\1", value)
    for old, new in _SPELLING:
        value = re.sub(rf"\b{old}\b", new, value)
    value = re.sub(r"\s+", " ", value).strip()
    # strip one pair of wrapping quotes
    pairs = [("„", "“"), ("»", "«"), ("\"", "\""), ("“", "”"), ("«", "»")]
    for o, c in pairs:
        if value.startswith(o) and (value.endswith(c) or value.endswith(c + ".")):
            inner = value[len(o):]
            inner = inner[: inner.rfind(c)] + inner[inner.rfind(c) + 1:]
            value = inner.strip()
            break
    return value


def text_key(value: str) -> str:
    """Aggressive normalisation used only for duplicate detection."""
    value = clean_verse(value).lower()
    value = value.replace("ß", "ss")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(ch for ch in value if ch.isalnum())
    return value


@dataclass(frozen=True)
class Ref:
    book: str
    chapter: int
    verses: frozenset[int]
    display: str

    def overlaps(self, other: "Ref") -> bool:
        return (
            self.book == other.book
            and self.chapter == other.chapter
            and bool(self.verses & other.verses)
        )


_REF_RE = re.compile(
    r"^(?P<num>[1-5])?\s*[.,]?\s*(?P<book>[A-Za-zÄÖÜäöüß]+)\.?\s*"
    r"(?P<chap>\d+)(?:\s*[,:]\s*(?P<v1>\d+)\s*[a-c]?)?"
    r"(?:\s*(?P<sep>[-–—+]|ff?\.?)\s*(?P<v2>\d+)?\s*[a-c]?)?\s*\.?$"
)


def parse_ref(raw: str) -> Ref | None:
    text = clean_text(raw)
    m = _REF_RE.match(text)
    if not m:
        return None
    key = (m.group("num") or "") + m.group("book").lower()
    book = _BOOK_LOOKUP.get(key) or _BOOK_LOOKUP.get(re.sub(r"brief$", "", key))
    if not book:
        return None
    chap = int(m.group("chap"))
    v1 = m.group("v1")
    v2 = m.group("v2")
    sep = m.group("sep") or ""
    if v1 is None:
        if book not in _SINGLE_CHAPTER:
            return None
        v1, chap = str(chap), 1
    start = int(v1)
    if sep.startswith("f"):
        end = start + (2 if sep.startswith("ff") else 1)
        verses = frozenset(range(start, end + 1))
        disp_v = f"{start}-{end}"
    elif v2 and sep == "+":
        verses = frozenset({start, int(v2)})
        disp_v = f"{start}.{v2}"
    elif v2:
        end = int(v2)
        if end < start:
            return None
        verses = frozenset(range(start, end + 1))
        disp_v = f"{start}-{end}"
    else:
        verses = frozenset({start})
        disp_v = str(start)
    display = f"{book} {disp_v}" if book in _SINGLE_CHAPTER else f"{book} {chap},{disp_v}"
    return Ref(book, chap, verses, display)
