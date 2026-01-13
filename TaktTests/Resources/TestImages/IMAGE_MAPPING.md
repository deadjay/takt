# Test Images Mapping

This document maps image files to their content type and expected dates for testing.

## Screenshots (Subscriptions)

### Screenshot 2026-01-06 at 19.10.36.jpeg
- **Content**: Apple Pay subscription dialog (one sec pro)
- **Type**: Subscription
- **Language**: English
- **Expected Date**: 6 Apr 2026
- **Price**: 14,99 € per year

### Screenshot 2026-01-06 at 19.12.13.jpeg
- **Content**: Apple Pay subscription dialog (Fabulous Premium)
- **Type**: Subscription
- **Language**: English
- **Expected Date**: 13 Jan 2026
- **Price**: 38,99 € per year

### Screenshot 2026-01-06 at 19.12.43.jpeg
- **Content**: Apple Pay subscription dialog (Fabulous Premium)
- **Type**: Subscription
- **Language**: German
- **Expected Date**: 13.01.2026 (Ab dem)
- **Price**: 38,99 € pro Jahr

### Screenshot 2026-01-06 at 19.18.17.jpeg
- **Content**: App Store Subscriptions page
- **Type**: Subscription list
- **Language**: English
- **Expected Dates**:
  - one sec pro: Continues 6 April
  - Various expired subscriptions

## Product Photos (Food Expiry)

### IMG_9485.jpeg - IMG_9487.jpeg
- **Content**: Chicken packaging (Hähnchen-Innenfilet)
- **Type**: Food expiry
- **Language**: German
- **Expected Date**: 30.12.25
- **Keywords**: "zu verbrauchen bis"

### IMG_9805.jpeg - IMG_9807.jpeg
- **Content**: Cheese packaging (Weidechart)
- **Type**: Food expiry
- **Language**: German
- **Expected Date**: 26.02.26
- **Additional**: NUTRI-SCORE label

### IMG_9808.jpeg, IMG_9810.jpeg
- **Content**: Milk packaging (Frische Vollmilch)
- **Type**: Food expiry
- **Language**: German
- **Expected Date**: 01.01. (year missing)

### IMG_9811.jpeg
- **Content**: Juice packaging
- **Type**: Food expiry
- **Expected Date**: 02/09/26

### IMG_9812.jpeg, IMG_9813.jpeg, IMG_9814.jpeg
- **Content**: Eggs packaging
- **Type**: Food expiry
- **Language**: German
- **Expected Date**: 23.01. (year missing)
- **Keywords**: "MINDESTENS HALTBAR BIS"

### IMG_9853.jpeg
- **Content**: Condensed milk can
- **Type**: Food expiry
- **Expected Date**: 21.08.2026

### IMG_9857.jpeg, IMG_9858.jpeg
- **Content**: Unknown (large files, likely product photos)
- **Type**: To be determined

## Usage Notes

- Use screenshots for subscription/billing tests
- Use product photos for food expiry deadline tests
- All tests should handle multiline text and noisy OCR output
- German text uses formats like "dd.MM.yy" or "dd.MM.yyyy"
- English uses formats like "13 Jan 2026" or "6 April"
