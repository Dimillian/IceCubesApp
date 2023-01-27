//
//  Action.js
//  IceCubesActionExtension
//
//  Created by Thomas Durand on 26/01/2023.
//

var Action = function() {};

Action.prototype = {
    run: function(arguments) {
        arguments.completionFunction({ "url" : document.URL })
    },
    finalize: function(arguments) {
        var openingUrl = arguments["deeplink"]
        if (openingUrl) {
            document.location.href = openingUrl
        }
    }
};
    
var ExtensionPreprocessingJS = new Action
