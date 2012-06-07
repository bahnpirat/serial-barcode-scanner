using Soup;
using GLib;

public class Web {

	private DatabaseHelper db;

	public Web(int port, DatabaseHelper db) {
		this.db = db;
		Server server = new Server(Soup.SERVER_PORT, port);
		server.add_handler("/buy", buy_handler);
		server.add_handler("/list", list_handler);
		server.add_handler("/delete", delete_handler);
		server.add_handler("/stats", stats_handler);
		server.run();
	}
	void buy_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
		stdout.printf("Path: %s\n", path);
		if(query != null) {
			stdout.printf("Length: %u\n", query.size());
			query.foreach((k,v) => {
				stdout.printf("%s -> %s\n", k, v);
			});
		}
		stdout.printf("[%d] %s\n", ((string)msg.request_body.flatten().data).length, (string)msg.request_body.flatten().data);
	}
	void stats_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
	}
	void list_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
	}
	void delete_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
	}
}
