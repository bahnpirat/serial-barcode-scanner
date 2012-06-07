public Device dev;
public ScannerSession ss;
public DatabaseHelper db;
public Web web;

public static int main(string[] args) {
	if(args.length < 2) {
		stderr.printf("%s <device>\n", args[0]);
		return 1;
	}

	dev = new Device(args[1], 9600, 8, 1);
	db = new DatabaseHelper("shop.db");
	ss = new ScannerSession(db);
	web = new Web(8080, db);

	dev.received_barcode.connect((data) => {
		if(interpret(data))
			dev.blink(10);
	});

	new MainLoop(null, false).run();
	return 0;
}

public static bool interpret(string data) {
	int64 timestamp = (new DateTime.now_utc()).to_unix();

	if(data.has_prefix("USER ")) {
		string str_id = data.substring(5);
		int32 id = int.parse(str_id);

		/* check if data has valid format */
		if(data != "USER %d".printf(id)) {
			stdout.printf("[%lld] ungültige Benutzernummer: %s\n", timestamp, data);
			return false;
		}

		if(ss.is_logged_in()) {
			stdout.printf("[%lld] Last User forgot to logout!\n", timestamp);
			ss.logout();
		}

		stdout.printf("[%lld] Login: %d\n", timestamp, id);
		return ss.login(id);
	} else if(data == "GUEST") {
		if(ss.is_logged_in()) {
			stdout.printf("[%lld] Last User forgot to logout!\n", timestamp);
			ss.logout();
		}

		stdout.printf("[%lld] Login: Guest\n", timestamp);
		return ss.login(0);
	} else if(data == "UNDO") {
		if(!ss.is_logged_in()) {
			stdout.printf("[%lld] Can't undo if not logged in!\n", timestamp);
			return false;
		} else {
			stdout.printf("[%lld] Undo last purchase!\n", timestamp);
			return ss.undo();
		}
	} else if(data == "LOGOUT") {
		if(ss.is_logged_in()) {
			stdout.printf("[%lld] Logout!\n", timestamp);
			return ss.logout();
		}

		return false;
	} else if(data == "STOCK") {
		if(!ss.is_logged_in()) {
			stdout.printf("[%lld] You must be logged in to go into the stock mode\n", timestamp);
			return false;
		} else {
			stdout.printf("[%lld] Going into stock mode!\n", timestamp);
			return ss.enter_stock_mode();
		}
	} else if(ss.is_in_stock_mode()) {
		if(!data.has_prefix("AMOUNT")) {
			uint64 id = uint64.parse(data);

			/* check if data has valid format */
			if(data != "%llu".printf(id)) {
				stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
				return false;
			}

			stdout.printf("[%lld] wähle Produkt: %s\n", timestamp, ss.get_product_name(id));

			return ss.choose_stock_product(id);
		} else {
			uint64 amount = uint64.parse(data.substring(7));

			/* check if data has valid format */
			if(data != "AMOUNT %llu".printf(amount)) {
				stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
				return false;
			}

			stdout.printf("[%lld] zum Bestand hinzufügen: %llu\n", timestamp, amount);

			return ss.add_stock_product(amount);
		}
	} else {
		uint64 id = uint64.parse(data);

		/* check if data has valid format */
		if(data != "%llu".printf(id)) {
			stdout.printf("[%lld] ungültiges Produkt: %s\n", timestamp, data);
			return false;
		}

		if(ss.buy(id)) {
			stdout.printf("[%lld] gekaufter Artikel: %s\n", timestamp, ss.get_product_name(id));
			return true;
		} else {
			stdout.printf("[%lld] Kauf fehlgeschlagen!\n", timestamp);
			return false;
		}
	}
}
