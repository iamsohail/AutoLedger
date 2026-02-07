# AutoLedger Style Guide

## Text Capitalization Rules

### Title Case (Short Text - 2 Lines or Less)

For short text elements, use **Title Case** - capitalize the first letter of every word **EXCEPT** for these exception words:
- **Articles:** a, an, the
- **Conjunctions:** and, but, or, nor
- **Prepositions:** as, at, by, for, from, in, into, of, on, onto, per, to, with, without
- **Pronouns (short):** you, your, yours, me, my, mine, it, its

**Where to Apply Title Case:**
- Navigation titles
- Button labels
- Section headers
- Card titles and subtitles
- Short descriptions (1-2 lines)
- Error messages (short)
- Placeholder text
- Menu items

**Examples:**

| Incorrect | Correct |
|-----------|---------|
| Log fuel purchases | Log Fuel Purchases |
| Track your spending over time | Track your Spending over Time |
| Schedule oil changes | Schedule Oil Changes |
| Enable camera access | Enable Camera Access |

**Notes:**
- The first word is always capitalized, even if it's an exception word
- The last word is always capitalized, even if it's an exception word
- Words after a colon are capitalized

---

### Sentence Case (Paragraphs - More Than 2 Lines)

For longer text (paragraphs, descriptions over 2 lines), use **Sentence Case** - only capitalize the first word and proper nouns.

**Where to Apply Sentence Case:**
- Permission request explanations
- Long descriptions
- Help text
- Onboarding explanations
- Terms and conditions
- Privacy policy content

**Examples:**

| Type | Text |
|------|------|
| Title Case | "Enable Camera Access" |
| Sentence Case | "Quickly scan fuel receipts and bills instead of typing everything manually. Just point your camera at the receipt and we'll capture the details for you." |

## Typography

Use `Theme.Typography` for consistent fonts throughout the app:

```swift
// Titles
Theme.Typography.largeTitle   // 34pt bold
Theme.Typography.title        // 28pt bold
Theme.Typography.title2       // 22pt bold
Theme.Typography.title3       // 20pt semibold

// Headlines & Body
Theme.Typography.headline     // 17pt semibold
Theme.Typography.body         // 17pt regular
Theme.Typography.subheadline  // 15pt regular

// Small Text
Theme.Typography.caption      // 12pt regular
Theme.Typography.footnote     // 13pt regular

// Stats (rounded design)
Theme.Typography.statValue       // 48pt bold rounded
Theme.Typography.statValueMedium // 36pt bold rounded
Theme.Typography.statValueSmall  // 24pt bold rounded
```

## Colors

Use semantic color names from Assets:
- `Color.darkBackground` - Pure black (#000000)
- `Color.cardBackground` - Card surfaces
- `Color.primaryPurple` - Primary accent
- `Color.greenAccent` - Fuel/success states
- `Color.pinkAccent` - Secondary accent
- `Color.textPrimary` - White text
- `Color.textSecondary` - Gray text
