public class ScannerSession {
	private DatabaseHelper db;
	private int32 user = 0;
	private uint64 product = 0;
	private bool logged_in = false;
	private bool stock_mode = false;

	public ScannerSession(DatabaseHelper db) {
		this.db = db;
	}

	public bool login(int32 id) {
		user = id;
		logged_in = true;
		return true;
	}
	public bool logout() {
		user = 0;
		stock_mode = false;
		logged_in = false;
		return true;
	}
	public bool buy(uint64 article) {
		if(logged_in) {
			return db.buy(user, article);
		}
		return false;
	}
	public string get_product_name(uint64 article) {
		string name;

		if(db.get_product_name(article, out name))
			return name;
		else
			return "unbekanntes Produkt: %llu".printf(article);
	}
	public bool undo() {
		if(logged_in) {
			return db.undo_last(user);
		}
		return false;
	}
	public bool enter_stock_mode() {
		if(logged_in)
			stock_mode = true;
		return stock_mode;
	}
	public bool choose_stock_product(uint64 id) {
		if(logged_in && stock_mode) {
			product = id;
			return true;
		}
		return false;
	}
	public bool add_stock_product(uint64 amount) {
		if(logged_in && stock_mode && product != 0) {
			return db.add_stock(user, product, (int)amount);
		}
		return false;
	}
	public bool is_logged_in() {
		return logged_in;
	}
	public bool is_in_stock_mode() {
		return stock_mode;
	}
}
