var Action = function() {};

Action.prototype = {

run: function(arguments) {
    arguments.completionFunction({"url" : document.URL});
},

finalize: function(arguments) {
    // This method is run after the extension "returns" to the host app.
    // The only functionality available to your JavaScript is to finalize your process.
    // The host app can pass back specific information to your extension through the "arguments" parameter.
}
    
};

var ExtensionPreprocessingJS = new Action;
