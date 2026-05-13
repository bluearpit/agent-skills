---
name: web-scraper
description: Scrape structured data from websites using Playwright browser automation. Use when the user wants to extract data from a website, scrape pages, collect listings, or download tabular data — especially from JavaScript-rendered pages (SPAs, Angular, React) where simple HTTP requests won't work.
argument-hint: "[url]"
---

## Task

Build a Playwright-based scraper to extract structured data from a website and save it locally (CSV/JSON).

## Phase 1: Reconnaissance

Before writing any code, understand the target page:

1. **Ask the user** (if not already provided):
   - What URL to scrape?
   - What data fields do they want extracted?
   - Should it handle pagination? (How many pages?)
   - Any filters to apply (e.g. "Active only", specific category)?
   - What output format? (CSV is default, JSON if nested data)

2. **Inspect the page** — ask the user to provide one of:
   - The page's HTML source (right-click > View Source, or DevTools Elements panel)
   - The visible text content of the page
   - A screenshot of the page

   This is critical because you cannot browse the web yourself. You need the user to share page structure so you can identify:
   - Whether it's a JavaScript SPA (Angular/React/Vue) or server-rendered HTML
   - Form controls that need interaction (dropdowns, submit buttons) before data appears
   - The exact element IDs, classes, and selectors for data extraction
   - Pagination mechanism (Next button, page numbers, infinite scroll, URL params)
   - Whether data is in a `<table>`, `<div>` list, or rendered by JS framework (ng-repeat, v-for, etc.)

3. **Identify the interaction flow** — many pages don't show data on initial load:
   - Dropdowns that must be selected first (check `<select>` elements and their `id`/`value` attributes)
   - Submit/Search buttons that must be clicked after selecting filters
   - Tabs or accordions that reveal content
   - Login walls or cookie consent dialogs
   - Note: look for the ACTUAL form element IDs in the HTML, not guessed ones. Case sensitivity matters.

## Phase 2: Script Design

4. **Create a standalone Python script** (no app dependencies) in `scripts/`:
   - Use `playwright.async_api` with `async_playwright()`
   - Set a realistic user agent string
   - Default to `headless=False` so the user can watch and debug. Add `--headless` flag to opt in.
   - Use generous timeouts (120-180s for initial page load, 60s for interactions)
   - Add `--output` flag with a sensible default path

5. **Page interaction pattern:**
   ```
   goto(url) → wait for page ready → interact with controls → wait for data → extract → paginate
   ```

   Key mistakes to avoid:
   - Don't guess element selectors — use exact IDs/classes from the HTML the user provided
   - Don't assume data loads on page open — check if form submission is required
   - Don't use `inner_text("body")` if you need links/attributes from elements — use `query_selector_all` on the actual table/list
   - Don't assume `<select>` dropdowns trigger data load on change — there may be a separate Submit button
   - Watch for multiple elements matching the same selector (e.g. two `<select>` dropdowns on the page)

6. **Data extraction approach:**
   - For `<table>` data: use `query_selector_all("table.classname tr")` then `query_selector_all("td")` per row
   - For JS-rendered lists: wait for the framework to render (`wait_for_function` checking element count)
   - For links/attributes: use `query_selector("a")` then `get_attribute("href")` — `inner_text` strips these
   - Always validate parsed data (e.g. regex check on IDs, skip header rows)

7. **Pagination handling:**
   - Detect total pages from page text (e.g. "Page 1 of 425")
   - Click Next button and wait for content to update before parsing
   - Check if Next button is disabled to detect last page
   - Use `wait_for_function` to confirm page transition (e.g. old page number disappears)
   - Add a small delay (1s) between pages to avoid rate limiting
   - Log progress: `Page X/Y — parsed N items (M total so far)`

8. **Output:**
   - Save as CSV with all extracted fields
   - Log summary at the end: total items saved, output path
   - Structure the script so the data can later be loaded into a DB without re-scraping

## Phase 3: Test and Iterate

9.  **Run the script yourself first** (headless) before asking the user to run it
10. If it fails or the selectors don't match, ask the user for updated page HTML/text and adjust
11. Common issues to watch for:
    - Timeout on page load: increase timeout, check if the page requires interaction first
    - 0 items parsed: wrong table/list selector, or data hasn't rendered yet
    - Wrong dropdown selected: multiple dropdowns on page, verify exact `id` attribute
    - Pagination stuck: Next button selector wrong, or page number format doesn't match regex

## Reference: Playwright Patterns

```python
# Launch browser
async with async_playwright() as pw:
    browser = await pw.chromium.launch(headless=False)
    context = await browser.new_context(user_agent="...", viewport={"width": 1920, "height": 1080})
    page = await context.new_page()

# Navigate with timeout
await page.goto(url, wait_until="domcontentloaded", timeout=180_000)

# Wait for element
await page.locator("select#myDropdown").wait_for(state="visible", timeout=60_000)

# Select dropdown option
await page.locator("select#myDropdown").select_option(value="optionValue")

# Click button
await page.locator("#submitBtn").click()

# Wait for JS-rendered content
await page.wait_for_function("() => document.querySelectorAll('table.data tr').length > 1", timeout=60_000)

# Extract from table rows (preserves links/attributes)
rows = await page.query_selector_all("table.data tr")
for tr in rows:
    cells = await tr.query_selector_all("td")
    text = (await cells[0].inner_text()).strip()
    link_el = await cells[0].query_selector("a")
    href = (await link_el.get_attribute("href")) or "" if link_el else ""

# Pagination
next_btn = page.locator("button:has-text('Next')").first
if await next_btn.is_disabled():
    break
await next_btn.click()
await page.wait_for_function(f"() => !document.body.innerText.includes('Page {current} of')", timeout=30_000)
```
