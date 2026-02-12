# IframeManager set-up
How to properly set up ConsentManager and IframeManager so that changes in state are reflected in both plugins.

Checkout the [demo on Stackblitz](https://stackblitz.com/edit/web-platform-ahqgz3?file=index.js).

::: info Info
This is an example config. and assumes that all iframes belong to the `analytics` category.
:::

## Connect IframeManager -> ConsentManager
When an iframe is accepted via a button click we must notify ConsentManager using the `onChange` callback:

::: warning Note
The `onChange` callback is available in iframemanager v1.2.0+.
:::

```javascript
const im = iframemanager();

im.run({
    onChange: ({ changedServices, eventSource }) => {
        if(eventSource.type === 'click') {
            const servicesToAccept = [
                ...ConsentManager.getUserPreferences().acceptedServices['analytics'],
                ...changedServices
            ];

            ConsentManager.acceptService(servicesToAccept, 'analytics');
        }
    },

    services: {
        youtube: {
            // ...
        },

        vimeo: {
            // ...
        }
    }
});
```

## Connect ConsentManager -> IframeManager
Enable/disable iframes via ConsentManager:

```javascript
ConsentManager.run({
    categories: {
        analytics: {
            services: {
                youtube: {
                    label: 'Youtube Embed',
                    onAccept: () => im.acceptService('youtube'),
                    onReject: () => im.rejectService('youtube')
                },
                vimeo: {
                    label: 'Vimeo Embed',
                    onAccept: () => im.acceptService('vimeo'),
                    onReject: () => im.rejectService('vimeo')
                }
            }
        }
    }
})
```

<br>

For more examples or details about the configuration options, checkout the [iframemanger](https://github.com/author/iframemanager) repo.