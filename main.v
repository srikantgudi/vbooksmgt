module main

import db.sqlite
import veb

// context struct must embed `veb.Context`!
pub struct Context {
	veb.Context
pub mut:
	session_id string
}

pub struct App {
pub:
	// In the app struct we store data that should be accessible by all endpoints.
	// For example, a database or configuration values.
	secret_key string
	db         sqlite.DB
}

// index route
pub fn (app &App) index(mut ctx Context) veb.Result {
	title := 'V-lang Books Management App'
	return $veb.html('index')
}

// home route
pub fn (app &App) home(mut ctx Context) veb.Result {
	return $veb.html('home')
}

// new book route
@['/newbook'; get]
pub fn (app &App) newbook(mut ctx Context) veb.Result {
	return $veb.html('newbook')
}

// new post route
@['/addbook'; post]
pub fn (app &App) addbook(mut ctx Context) veb.Result {
	title := ctx.form['booktitle']
	author := ctx.form['bookauthor']
	yearpub := ctx.form['bookyearpub']
	price := ctx.form['bookprice']
	mut err := []string{}
	if title == '' {
		err << 'title is required'
	} else {
		check := app.db.exec_map('select * from books where title = "${title}"') or { panic(err) }
		if check.len > 0 {
			return ctx.text('"${title}" already exists')
		}
	}
	if author == '' {
		err << 'author is missing'
	}
	if yearpub == '' {
		err << 'year of publication is required'
	}
	if price == '' || price.f64() == 0 {
		err << 'price not entered or is zero'
	}
	if err.len == 0 {
		row := app.db.exec("insert into books (title,author,yearpub,price) values ('${title}','${author}','${yearpub}','${price}')") or {
			panic(err)
		}
		println('row = ${row}')
	}
	if err.len > 0 {
		return ctx.text('<ul style="color:maroon;font-size:12px"><li>' + err.join('</li><li>') +
			'</li></ul>')
	}
	return ctx.text("<button hx-get='/newbook' hx-target='#content'>New book</button><button hx-get='/showbooks' hx-target='#content'>View List</button>")
}

@['/showbooks'; get]
fn (app &App) bookslist(mut ctx Context) veb.Result {
	mut res := app.db.exec_map('Select * From books') or { panic('error fetching books ${err}') }
	return $veb.html('bookslist')
}

fn main() {
	mut app := &App{
		secret_key: 's3crEt'
		db:         sqlite.connect('books.db') or { panic(err) }
	}
	// Pass the App and context type and start the web server on port 8080
	veb.run[App, Context](mut app, 8080)
}
