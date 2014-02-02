/*
 * Thyrd
 *
 * Main entry point, sets up require.js which will
 * handle everything else.
 */

// Unique object ids, for debugging
var __obj_id_counter = 1;
objectId = function(obj) {
    if(obj == null) return null;
    if(obj.__obj_id == null) obj.__obj_id = __obj_id_counter++;
    return obj.__obj_id;
}

debug = function(args) {
    console.log.apply(console, arguments);  // comment out this line for production
};

requirejs.config({
    baseUrl: 'js',
    shim: {
        'lib/zepto.min': ['lib/setup_prior_to_libraries'],
        'lib/mustache': ['lib/zepto.min'],
        'app/init': ['lib/mustache'],
        'app/core': ['app/init']
}
});

require([
    'lib/setup_prior_to_libraries',
//    'lib/less.min',
    'lib/zepto.min', 
    'lib/mustache', 
    'app/init',
    'app/core' 
], function() {
});

