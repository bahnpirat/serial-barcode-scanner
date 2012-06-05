using Soup;
using GLib;

public class Web {

	public Web(int port) {
		Server server = new Server(Soup.SERVER_PORT, port);
		server.add_handler("/rest", rest_handler);
		server.run();
	}
	void rest_handler(Server server, Message msg, string path, HashTable<string,string>? query, ClientContext client) {
		stdout.printf("Length: %u\n", query.size());
		query.foreach((k,v) => {
			stdout.printf("%s -> %s\n", k, v);
		});
		stdout.printf("%s\n", (string)msg.request_body.flatten().data);
	}
}
