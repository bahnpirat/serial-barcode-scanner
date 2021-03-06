/* Copyright 2012, Sebastian Reichel <sre@ring0.de>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

public errordomain WebSessionError {
	SESSION_NOT_FOUND,
	USER_NOT_FOUND
}

public class WebSession {
	public int user {
		get;
		private set;
		default = 0;
	}
	public string name {
		get;
		private set;
		default = "Guest";
	}
	public bool failed {
		get;
		private set;
		default = false;
	}
	public bool logged_in {
		get;
		private set;
		default = false;
	}
	public bool superuser {
		get;
		private set;
		default = false;
	}
	public bool disabled {
		get;
		private set;
		default = false;
	}

	private string generate_session_id(int user) {
		const string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
		string result = "";

		Random.set_seed((uint32) time_t() + (uint32) Posix.getpid() + (uint32) user);

		for(int i=0; i<19; i++) {
			int character_position = Random.int_range(0,charset.length);
			string character = charset[character_position].to_string();
			result += character;
		}

		/* TODO: make sure, that session id is unique */

		return result;
	}

	private void setup_auth(int user) {
		var auth = db.get_user_auth(user);
		this.disabled  = auth.disabled;
		this.superuser = auth.superuser;
		this.logged_in = true;
	}

	public void logout() {
		if(logged_in) {
			db.set_sessionid(user, "");
			superuser = false;
			logged_in = false;
		}
	}

	public WebSession(Soup.Server server, Soup.Message msg, string path, GLib.HashTable<string,string>? query, Soup.ClientContext client) {
		var cookies = Soup.cookies_from_request(msg);

		/* Check for existing session */
		foreach(var cookie in cookies) {
			if(cookie.name == "session") {
				var sessionid = cookie.value;

				try {
					user = db.get_user_by_sessionid(sessionid);
					name = db.get_username(user);
					setup_auth(user);
					return;
				} catch(WebSessionError e) {
					/* invalid session, ignore */
				}
			}
		}

		/* check for login query */
		if(query == null || !query.contains("user") || !query.contains("password"))
			return;

		/* get credentials */
		var userid   = int.parse(query["user"]);
		var password = query["password"];

		/* check credentials */
		if(db.check_user_password(userid, password)) {
			/* generate session */
			var sessionid = generate_session_id(userid);

			/* set session in database */
			db.set_sessionid(userid, sessionid);

			/* set session in reply cookie */
			cookies = new SList<Soup.Cookie>();
			var sessioncookie = new Soup.Cookie("session", sessionid, "", "/", -1);
			sessioncookie.domain = null;
			cookies.append(sessioncookie);
			Soup.cookies_to_response(cookies, msg);

			/* login successful */
			user = userid;
			try {
				name = db.get_username(user);
			} catch(WebSessionError e) {
				name = "Unknown User";
			}

			setup_auth(user);
		} else {
			/* login failed */
			failed=true;
		}
	}
}

