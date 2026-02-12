# ConsentManager

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A **lightweight** & **GDPR compliant** cookie consent management plugin written in plain JavaScript.

## Features

- Lightweight, zero-dependency vanilla JavaScript
- GDPR & ePrivacy compliant
- Customizable consent modal and preferences modal
- Multiple layout options (box, cloud, bar)
- Dark/light color scheme support
- RTL language support
- Auto-detection of browser/document language
- Cookie autoclear when consent is revoked
- Script tag management via `data-category` attribute
- Services management (individually togglable)
- Revision management
- Full TypeScript support

## Installation

### Via npm / pnpm

```bash
npm install consent-manager
# or
pnpm install consent-manager
```

### Via CDN

```html
<link rel="stylesheet" href="dist/consent-manager.css" />
<script src="dist/consent-manager.umd.js"></script>
```

## Quick Start

```javascript
import * as ConsentManager from 'consent-manager';
import 'consent-manager/dist/consent-manager.css';

ConsentManager.run({
    categories: {
        necessary: {
            readOnly: true,
            enabled: true
        },
        analytics: {}
    },
    language: {
        default: 'en',
        translations: {
            en: {
                consentModal: {
                    title: 'We use cookies',
                    description: 'We use cookies to ensure basic functionality and to improve your experience.',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    showPreferencesBtn: 'Manage preferences'
                },
                preferencesModal: {
                    title: 'Cookie Preferences',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject all',
                    savePreferencesBtn: 'Save preferences',
                    closeIconLabel: 'Close',
                    sections: [
                        {
                            title: 'Cookie Usage',
                            description: 'We use cookies to ensure basic functionality and to improve your online experience.'
                        },
                        {
                            title: 'Strictly Necessary',
                            description: 'These cookies are essential for the website to function properly.',
                            linkedCategory: 'necessary'
                        },
                        {
                            title: 'Analytics',
                            description: 'These cookies help us understand how visitors interact with our website.',
                            linkedCategory: 'analytics'
                        }
                    ]
                }
            }
        }
    }
});
```

## Development

### Prerequisites

- [Node.js LTS](https://nodejs.org/en/download/)
- [pnpm](https://pnpm.io/) (`npm i -g pnpm`)

### Setup

```bash
pnpm install
```

### Dev mode (watch)

```bash
pnpm dev
```

### Build

```bash
pnpm build
```

### Run tests

```bash
pnpm test
```

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
