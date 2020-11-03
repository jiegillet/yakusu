// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Elm

import { Elm } from "../elm/src/Main.elm";

var storageKey = "store";
var storedData = localStorage.getItem(storageKey);
var flags = storedData ? JSON.parse(storedData) : null;

var app = Elm.Main.init({ flags: flags });

app.ports.store.subscribe(function(val) {
  // console.log(val); 

  if (val === null) {
    localStorage.removeItem(storageKey);
  } else {
    localStorage.setItem(storageKey, JSON.stringify(val));
  }

  // Report that the new session was stored successfully.
  setTimeout(function() { app.ports.onStoreChange.send(val); }, 0);
});

// Whenever localStorage changes in another tab, report it if necessary.
window.addEventListener("storage", function(event) {
  if (event.storageArea === localStorage && event.key === storageKey) {
    app.ports.onStoreChange.send(JSON.parse(event.newValue));
  }
}, false);
