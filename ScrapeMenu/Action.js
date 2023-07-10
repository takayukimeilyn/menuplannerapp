var Action = function() {};

Action.prototype = {

run: function(arguments) {
    let jsonScripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
    let data = {};
    for (let script of jsonScripts) {
        let json = JSON.parse(script.innerText);
        if (json.name && json.recipeIngredient) {
            data.title = json.name;
            data.yield = json.recipeYield || ""; // If recipeYield is null, set it as an empty string
            data.ingredients = [];
            data.units = [];
            for (let ingredient of json.recipeIngredient) {
                let split = ingredient.split(' ');
                data.ingredients.push(split[0]);
                data.units.push(split.slice(1).join(' '));
            }
            data.images = json.image || [];
            break;
        }
    }
    data.url = window.location.href;
    arguments.completionFunction(data);
    console.log('Sent data to Swift');
},

finalize: function(arguments) {
    // This method is run after the extension "returns" to the host app.
}
};

var ExtensionPreprocessingJS = new Action;
