# :Yakusu

:Yakusu is a tool to help translating children books, printing the translations with a label maker and pasting the labels at the appropriate locations.

The translating workflow is designed in 3 phases that can be done by different people:

#### Uploading

Basic information (title, author, language, theme) and pictures of the pages are uploaded on the server. The images are saved greyed out and blurred to a point where text is no longer readable to avoid any reproduction of the book. 

All the uploaded books and translations are visible and accessible from the home page.

#### Translating

A book translation in a specific language is created. The translator draws colored blobs on the pages and adds translations for those specific areas. This is especially useful for non-linear picture books.

Translators can leave translation notes, and choose to save or not.

#### Labeling

Book translations can be downloaded in text format suitable for direct copy/pasting into a label maker software. The text is divided into chunks adjusted for the maximum printable label size and further divided with white spaces to show where the labels should be cut.

The labels are pasted on the book. The location for each label can be identified from the colored blobs drawn by the translator, so that the labeller does not need to know the book original language.


## Authors 

User Interface Design: Maria Gohlke <MARIA.GOHLKE@OIST.JP>

Coding: Jeremie Gillet <jie.gillet@gmail.com>

## Running :Yakusu

:Yakusu is built with Elixir and Phoenix, and uses PostgreSQL for a database. ImageMagick is also used for manipulating images.

To run :Yakusu:

  * Install Elixir, Phoenix, PostgreSQL and ImageMagick.
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

