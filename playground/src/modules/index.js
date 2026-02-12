import * as ConsentManager from '../../../dist/consent-manager.esm'
import { fireEvent, customEvents } from './utils';
import { getCurrentUserConfig, getState, clearInvalidDemoState } from './stateManager';

import './categories'
import './language'
import './translations'
import './translationEditor'
import './guiOptions'
import './misc'
import './customThemes'
import './downloadConfig'

window.ConsentManager = ConsentManager;

clearInvalidDemoState();
fireEvent(customEvents._PLAYGROUND_READY);

ConsentManager
    .run(getCurrentUserConfig(getState()))
    .then(() => {
        fireEvent(customEvents._INIT);
    });