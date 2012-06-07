using Soup;
using GLib;
using Json;

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
		string[] parameters = path.split("/");
		int64 from, to;
		size_t len;
		List<Sale> sales;
		Builder b;
		Generator g;

		if(parameters.length > 2)
			from = int64.parse(parameters[2]);
		else
			from = (new DateTime.now_utc()).to_unix() - 24 * 60 * 60;

		if(parameters.length > 3)
			to = int64.parse(parameters[3]);
		else
			to = (new DateTime.now_utc()).to_unix();

		sales = db.sold_products(from, to);

		g = new Generator();
		b = new Builder();
		b.begin_object();
		b.set_member_name("sales");
		b.begin_array();
		foreach(unowned Sale s in sales) {
			b.begin_object();
			b.set_member_name("article");
			b.add_int_value(s.article);
			b.set_member_name("product");
			b.add_string_value(s.product_name);
			b.set_member_name("timestamp");
			b.add_int_value(s.timestamp);
			b.end_object();
		}
		b.end_array();
		b.end_object();

		g.root = b.get_root();
		msg.set_response("application/json", Soup.MemoryUse.COPY, g.to_data(out len).data);
	}
	void delete_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
	}
}
