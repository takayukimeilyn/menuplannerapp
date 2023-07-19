var Action = function() {};

Action.prototype = {

//run: function(arguments) {
//    let jsonScripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
//    let data = {};
//    for (let script of jsonScripts) {
//        let json = JSON.parse(script.innerText);
//        if (json.name && json.recipeIngredient) {
//            data.title = json.name;
//            data.yield = json.recipeYield || ""; // If recipeYield is null, set it as an empty string
//            data.ingredients = [];
//            data.units = [];
//            for (let ingredient of json.recipeIngredient) {
//                let split = ingredient.split(' ');
//                let units = split.slice(1).join(' ');
//                if (units) { // Add this condition
//                    data.ingredients.push(split[0]);
//                    data.units.push(units);
//                }
//            }
//            data.images = json.image || [];
//            if (data.units.length === 0) { // If units are still empty after the loop, delete ingredients
//                delete data.ingredients;
//            }
//            break;
//        }
//    }
//    data.url = window.location.href;
//    arguments.completionFunction(data);
//    console.log('Sent data to Swift');
//},
    
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
                let units = split.slice(1).join(' ');
                if (units) { // Add this condition
                    data.ingredients.push(split[0]);
                    data.units.push(units);
                }
            }
            data.images = json.image || [];
            if (data.units.length === 0) { // If units are still empty after the loop, delete ingredients
                delete data.ingredients;
            }
            // Add the following lines to extract recipeInstructions and cookTime
            if (json.recipeInstructions) {
                data.instructions = json.recipeInstructions.map(instruction => instruction.text);
            }
            data.cookTime = json.cookTime || ""; // If cookTime is null, set it as an empty string
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
