# Rulehive — Board Game Rules

Category: Board Games & Reference · Platform: iOS 17+ · Bundle: `com.shimondeitel.rulehive`

## Concept

Photograph the pages of a physical board-game rulebook once — one photo per page or
two-page spread — and Rulehive OCRs and indexes the text. Mid-game, when a dispute
comes up ("can you trade during setup?"), type the question and Rulehive searches
across every indexed page and jumps straight to the most relevant one: the extracted
text plus which page it came from. This is not a photo-perfect rulebook renderer —
just the text, tied to a page label, searchable instantly.

## Problem / evidence

Every board-game table has had the same argument: someone half-remembers a rule,
nobody wants to flip through a 40-page rulebook mid-turn to find the one paragraph
that settles it, and the official app for a given game (if one exists at all) is
usually a full digital implementation, not a quick rules-lookup tool. A phone camera
plus a vision model can already read a page of printed rules; the missing piece is
turning a shelf of physical rulebooks into something searchable in ten seconds.

## Free tier

- Photograph and index up to 3 games at once.
- Full search within each indexed game's pages, no page-count limit per game.

## Pro — $3.99/month (auto-renewable subscription, `com.shimondeitel.rulehive.pro.monthly`)

- Unlimited games indexed at once.
- Everything else about search and indexing is identical to free — Pro removes the
  library cap, it does not gate search quality.

## Animation hook

The signature "thumb through pages" reveal: after a search executes, a fan of
page-edge cards riffles in a staggered `rotation3DEffect`/spring sequence (each card
delayed a beat behind the last) and settles on the matched page, which pops forward
and highlights in the gold accent — a satisfying, tactile stand-in for physically
flipping to the right page, not just an instant list of results.

## AI feature (vision)

One call per rulebook page photo to the shared no-key proxy's `/vision` route (it
forwards only the first image per request, so multi-page rulebooks are one sequential
call per page as they're added):

1. `transcribePage(photo)` asks the model to transcribe every piece of visible text
   verbatim, in reading order, with no summarization — this is OCR-style
   transcription, not a description, so a search for an exact phrase from the
   rulebook still finds it.
2. `AIProxyClient.cleanTranscription` strips any markdown fences or leading chatter
   the model adds despite being told not to, so only the transcription itself is
   stored and indexed.
3. `SearchEngine.search` (pure, unit-tested Swift, no network) ranks every indexed
   page for a typed query by keyword/substring occurrence count plus an exact-phrase
   bonus, returns the ranked hits with a short context snippet, and the top hit drives
   which page the flip animation settles on.

## Design direction

Warm parchment paper background with a deep rulebook-cover maroon as the secondary
surface color and **one** vivid gold-foil accent reserved *only* for the search/AI
hook, matched-page highlights, and the Pro call-to-action — never ordinary chrome.
Shape language is a soft "hardback book": rounded card corners with a spine-accent bar
down the left edge of every panel, serif display type for titles. This is the
deliberate opposite of a sharp/technical template.

## Monetization

Monthly auto-renewable subscription, $3.99/mo, StoreKit 2 with a real
`Transaction.currentEntitlements` / `Transaction.updates` listener and a
`Rulehive.storekit` local test configuration. Free tier indexes up to 3 games with
full search; Pro removes the game-count cap.
