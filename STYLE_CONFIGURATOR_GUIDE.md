# 🎨 Style Configurator - User Guide

## Overview

The live demo now includes an interactive **Style Configurator** that allows users to customize the consent banner appearance in real-time and generate the configuration code.

## Features

### 1. **Color Customization** 🎨
- **Primary Color**: Main brand color for buttons and accents
- **Background Color**: Banner background
- **Text Color**: Main text color
- **Button Text Color**: Text color on primary buttons

### 2. **Layout & Position** 📐
- **Layout Types**:
  - `box` - Compact box layout (default)
  - `cloud` - Rounded cloud-style banner
  - `bar` - Full-width bar
  
- **Positions**:
  - `bottom` - Bottom center
  - `middle` - Center of screen
  - `top` - Top center
  - `bottom left` - Bottom left corner
  - `bottom right` - Bottom right corner

- **Transition**:
  - `slide` - Slide in animation
  - `zoom` - Zoom in animation

### 3. **Typography** 📝
- **Font Size**: 12px - 20px (default: 14px)
- **Border Radius**: 0px - 30px (default: 12px)
- **Button Radius**: 0px - 30px (default: 8px)

### 4. **Advanced Options** ⚙️
- **Preferences Layout**: Box or Wide
- **Preferences Position**: Center, Left, or Right
- **Button Order**: Accept First or Reject First

## How to Use

### Step 1: Customize
1. Open the demo page
2. Scroll to the "🎨 Style Configurator" section
3. Adjust colors, layout, position, and other settings
4. Watch the values update in real-time

### Step 2: Apply
Click the **"✨ Apply Style"** button to:
- Apply your custom styles
- Auto-open the consent banner to preview changes
- See the styled banner in action

### Step 3: Get the Code
Click the **"📋 Show Configuration Code"** button to:
- Display the complete configuration code
- See both JavaScript config and CSS styles
- Click anywhere on the code to copy it to clipboard

### Step 4: Integrate
1. Copy the generated code
2. Add the `guiOptions` to your ConsentManager initialization
3. Add the custom CSS to your stylesheet
4. Done! Your consent banner now matches your brand

## Example Configuration

```javascript
// Generated configuration example
ConsentManager.run({
    // ... your existing configuration ...
    
    guiOptions: {
        consentModal: {
            layout: 'box',
            position: 'bottom',
            transition: 'slide',
            flipButtons: false
        },
        preferencesModal: {
            layout: 'box',
            position: 'center',
            transition: 'slide',
            flipButtons: false
        }
    }
});
```

```css
/* Custom styles */
:root {
    --cm-primary-color: #667eea;
    --cm-bg-color: #ffffff;
    --cm-text-color: #2c3e50;
}

#cm-consent-modal,
#cm-preferences-modal {
    font-size: 14px !important;
}

#cm-consent-modal .cm,
#cm-preferences-modal .cm {
    background-color: #ffffff !important;
    color: #2c3e50 !important;
    border-radius: 12px !important;
}

#cm-consent-modal .cm-btn-primary,
#cm-preferences-modal .cm-btn-primary {
    background-color: #667eea !important;
    color: #ffffff !important;
}
```

## Features & Benefits

### For Potential Clients
- ✅ **Live Preview**: See exactly how the banner will look
- ✅ **Brand Matching**: Easy to match company colors and style
- ✅ **Copy-Paste Ready**: Generated code is ready to use
- ✅ **No Technical Skills**: Visual interface, no coding needed

### For Sales & Demos
- ✅ **Interactive Demo**: Let clients customize on the spot
- ✅ **Professional Presentation**: Shows flexibility and ease of use
- ✅ **Competitive Advantage**: Unlike Cookiebot/OneTrust, you can preview customization

### For Developers
- ✅ **Quick Prototyping**: Test different styles rapidly
- ✅ **Client Approvals**: Get visual approval before coding
- ✅ **Documentation**: Shows all available options

## UI Components Added

### HTML Structure
```html
<div class="demo-card">
    <h2>🎨 Style Configurator</h2>
    <div class="config-panel">
        <div class="config-grid">
            <!-- 4 config groups: Colors, Layout, Typography, Advanced -->
        </div>
        <div class="config-actions">
            <!-- 3 action buttons -->
        </div>
        <div class="code-output">
            <!-- Generated code display -->
        </div>
    </div>
</div>
```

### CSS Classes
- `.config-panel` - Main configurator container
- `.config-grid` - Responsive grid layout
- `.config-group` - Individual configuration sections
- `.config-item` - Single configuration option
- `.range-value` - Live value display for sliders
- `.code-output` - Code display area
- `.copy-success` - Success notification

### JavaScript Functions
- `updateStyle()` - Update range value displays
- `getConfigFromUI()` - Extract configuration from form
- `applyStyle()` - Apply styles and reinitialize
- `applyCustomCSS()` - Inject custom CSS
- `showCode()` - Generate and display code
- `resetStyle()` - Reset to defaults
- `showCopySuccess()` - Show success message

## Technical Details

### Real-time Updates
- Color pickers trigger immediate value updates
- Range sliders show live values
- Select boxes update configuration instantly

### CSS Injection
Custom styles are dynamically injected with ID `custom-consent-style` to override default styles without modifying the core library.

### Configuration Generation
The configurator generates both:
1. **JavaScript config** for `guiOptions`
2. **CSS styles** for visual customization

### Clipboard Integration
Click anywhere on the generated code to copy it to your clipboard automatically.

## Browser Support

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Mobile browsers (touch-friendly)

## Future Enhancements

Potential additions:
- [ ] Font family selector
- [ ] Shadow intensity slider
- [ ] Animation speed control
- [ ] Save/load configurations
- [ ] Preset themes (Material, Bootstrap, Tailwind)
- [ ] Dark mode toggle
- [ ] Export as JSON
- [ ] Share configuration via URL

## Marketing Points

Use these talking points when demoing:

1. **"Try before you buy"** - Customize live to match your brand
2. **"No developer needed"** - Visual interface for non-technical users
3. **"Instant results"** - See changes in real-time
4. **"Copy-paste integration"** - Code is ready to use
5. **"Unlimited customization"** - Match any brand guideline

## Support

For questions or issues:
- Check the demo: `/demo-live/index.html`
- Review generated code for syntax
- Test in different browsers
- Contact: Built by Conicle AI

---

**Status**: ✅ Fully implemented and ready for demos  
**Last Updated**: 2026-02-16  
**Demo URL**: `demo-live/index.html`
