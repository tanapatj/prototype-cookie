/**
 * The file is for demo purposes,
 * don't use in your configuration!
 */

const message = '❗ If you see this message, it means that you are viewing this demo file directly! You need a webserver to test cookies! <br><br><em>Ensure that the URL begins with "<i>http</i>" rather than "<i>file</i>"!</em>'

if(location.protocol.slice(0, 4) !== 'http'){
    const warning = document.createElement('p');
    warning.innerHTML = message;
    warning.className = 'warning';
    document.body.appendChild(warning);
}

const cookieSettingsBtn = document.querySelector('[data-cc="show-preferencesModal"]');
const resetCookiesBtn = document.createElement('button');
resetCookiesBtn.type = 'button';
resetCookiesBtn.className = 'btn';
resetCookiesBtn.innerText = 'Reset consent';
cookieSettingsBtn.parentNode.insertBefore(resetCookiesBtn, cookieSettingsBtn.nextSibling);

resetCookiesBtn.addEventListener('click', function(){
    ConsentManager.acceptCategory([]);
    ConsentManager.reset(true);
    ConsentManager.eraseCookies([/^(cm_)/, ConsentManager.getConfig('cookie').name, /^(im_)/]);
    window.location.reload();
});

/**
 * @param {HTMLElement} modal
 */
const updateFields = (modal) => {
    const {consentId, consentTimestamp, lastConsentTimestamp} = ConsentManager.getCookie();

    const id = modal.querySelector('#consent-id');
    const timestamp = modal.querySelector('#consent-timestamp');
    const lastTimestamp = modal.querySelector('#last-consent-timestamp');

    id && (id.innerText = consentId);
    timestamp && (timestamp.innerText = new Date(consentTimestamp).toLocaleString());
    lastTimestamp && (lastTimestamp.innerText = new Date(lastConsentTimestamp).toLocaleString());
}

window.addEventListener('cm:onModalReady', ({detail}) => {
    if(detail.modalName === 'preferencesModal'){
        ConsentManager.validConsent() && updateFields(detail.modal);
        window.addEventListener('cm:onChange', () => updateFields(detail.modal));
        window.addEventListener('cm:onConsent', () => updateFields(detail.modal));
    }
})
