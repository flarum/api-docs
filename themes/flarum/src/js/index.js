import '../less/index.less';

import $ from 'jquery';
window.jQuery = $;
window.$ = $;
import 'bootstrap/dist/js/bootstrap.bundle.min';
// import Bloodhound from 'typeahead.js/dist/bloodhound';
// window.Bloodhound = Bloodhound;
import typeahead from './typeahead.0.11.1';

typeahead($);