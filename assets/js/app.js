// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import {Socket} from "phoenix"
let socket = new Socket("/socket", {})
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("book:add", {})
channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

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

app.ports.broadcastBook.subscribe(function(book) {
    console.log("Sending", book);
    channel.push("broadcast_book", {book: book})
        .receive("ok", payload => console.log("Response", payload))
        .receive("error", (reasons) => console.log("create failed", reasons) )
     .receive("timeout", () => console.log("Networking issue...") )

});

channel.on("broadcast_book", payload => {
    console.log(payload);
});
