# Firestore Data Structure for User Journey Static Data

This document outlines the proposed Firestore data structure for storing the static data related to the user journeys in the MeTrustual application.

## Collections

A new top-level collection named `journeys` will be created.

## Documents

Each document in the `journeys` collection will represent a specific user journey. The document ID will correspond to the mode identifier used in the application (e.g., `period`, `preg`, `ovul`).

### Journey Document Structure

Each journey document will contain the following fields:

- **`steps`**: An array of maps, where each map represents a step in the journey. This will contain the same data that is currently hardcoded in the `_getJourneySteps` function in `journey_screen.dart`.

#### Step Map Structure

Each step map will have the following fields:

- `icon` (String)
- `q` (String)
- `sub` (String)
- `type` (String)
- `key` (String)
- `required` (Boolean)
- `opts` (Array of maps)
- `warn` (String)
- `min` (Number)
- `max` (Number)
- `def` (Number)
- `unit` (String)
- `skip` (String)

## Example

Here is an example of the `period` journey document:

```json
{
  "steps": [
    {
      "icon": "🩸",
      "q": "When did your last period start?",
      "sub": "This helps us predict your next period and fertile window accurately.",
      "type": "date",
      "key": "lastPeriod",
      "required": false,
      "skip": "Not sure / this is my first time tracking"
    },
    // ... other steps
  ]
}
```
