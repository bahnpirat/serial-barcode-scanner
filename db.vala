using Sqlite;

public class DatabaseHelper {
	private Database db;
	private Statement user_stmt;
	private Statement imei_stmt;
	private Statement product_stmt;
	private Statement purchase_stmt1;
	private Statement purchase_stmt2;
	private Statement undo_stmt1;
	private Statement undo_stmt2;
	private Statement undo_stmt3;
	private Statement stock_stmt1;
	private Statement stock_stmt2;
	private static string user_query = "SELECT id FROM users WHERE id = ? LIMIT 1";
	private static string imei_query = "SELECT id FROM users WHERE imei = ? LIMIT 1";
	private static string product_query = "SELECT name FROM products WHERE id = ?";
	private static string purchase_query1 = "INSERT INTO purchases ('user', 'product', 'timestamp') VALUES (?, ?, ?)";
	private static string purchase_query2 = "UPDATE products SET amount = amount - 1 WHERE id = ?";
	private static string undo_query1 = "SELECT product FROM purchases WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
	private static string undo_query2 = "DELETE FROM purchases WHERE user = ? ORDER BY timestamp DESC LIMIT 1";
	private static string undo_query3 = "UPDATE products SET amount = amount + 1 WHERE id = ?";
	private static string stock_query1 = "INSERT INTO restock ('user', 'product', 'amount', 'timestamp') VALUES (?, ?, ?, ?)";
	private static string stock_query2 = "UPDATE products SET amount = amount + ? WHERE id = ?";

	public DatabaseHelper(string file) {
		int rc;

		rc = Database.open (file, out db);
		if(rc != OK) {
			error("could not open database!");
		}

		rc = this.db.prepare_v2(user_query, -1, out user_stmt);
		if(rc != OK) {
			error("could not prepare user statement!");
		}

		rc = this.db.prepare_v2(imei_query, -1, out imei_stmt);
		if(rc != OK) {
			error("could not prepare imei statement!");
		}

		rc = this.db.prepare_v2(purchase_query1, -1, out purchase_stmt1);
		if(rc != OK) {
			error("could not prepare first purchase statement!");
		}

		rc = this.db.prepare_v2(purchase_query2, -1, out purchase_stmt2);
		if(rc != OK) {
			error("could not prepare second purchase statement!");
		}

		rc = this.db.prepare_v2(product_query, -1, out product_stmt);
		if(rc != OK) {
			error("could not prepare article statement!");
		}

		rc = this.db.prepare_v2(undo_query1, -1, out undo_stmt1);
		if(rc != OK) {
			error("could not prepare first undo statement!");
		}

		rc = this.db.prepare_v2(undo_query2, -1, out undo_stmt2);
		if(rc != OK) {
			error("could not prepare second undo statement!");
		}

		rc = this.db.prepare_v2(undo_query3, -1, out undo_stmt3);
		if(rc != OK) {
			error("could not prepare third undo statement!");
		}

		rc = this.db.prepare_v2(stock_query1, -1, out stock_stmt1);
		if(rc != OK) {
			error("could not prepare first stock statement!");
		}

		rc = this.db.prepare_v2(stock_query2, -1, out stock_stmt2);
		if(rc != OK) {
			error("could not prepare second stock statement!");
		}

	}
	public bool user_exists(int32 id) {
		this.user_stmt.reset();
		this.user_stmt.bind_int(1, id);

		return this.user_stmt.step() == ROW;
	}
	public bool imei_exists(string imei, out int id) {
		this.imei_stmt.reset();
		this.imei_stmt.bind_text(1, imei);
		id = 0;

		if(this.imei_stmt.step() == ROW) {
			id = this.imei_stmt.column_int(0);
			return true;
		}
		return false;
	}
	public bool buy(int32 user, uint64 article) {
		int rc;
		int64 timestamp = (new DateTime.now_utc()).to_unix();

		this.purchase_stmt1.reset();
		this.purchase_stmt1.bind_int(1, user);
		this.purchase_stmt1.bind_int64(2, (int64)article);
		this.purchase_stmt1.bind_int64(3, timestamp);

		if((rc = this.purchase_stmt1.step()) != DONE)
			error("interner Fehler: %d]", rc);

		this.purchase_stmt2.reset();
		this.purchase_stmt2.bind_int64(1, (int64)article);

		if((rc = this.purchase_stmt2.step()) != DONE)
			error("interner Fehler: %d]", rc);

		return true;
	}
	public bool get_product_name(uint64 article, out string name) {
		this.product_stmt.reset();
		this.product_stmt.bind_int64(1, (int64)article);
		name = null;

		if(this.product_stmt.step() == ROW) {
			name = this.imei_stmt.column_text(0);
			return true;
		}
		return false;
	}
	public bool undo_last(int32 user) {
		uint64 pid;
		int rc;

		this.undo_stmt1.reset();
		this.undo_stmt1.bind_int(1, user);

		if((rc = this.undo_stmt1.step()) == ROW)
			pid = this.undo_stmt1.column_int64(0);
		else if(rc == DONE)
			return false;
		else
			error("[interner Fehler: %d]", rc);

		this.undo_stmt2.reset();
		this.undo_stmt2.bind_int(1, user);

		if((rc = this.undo_stmt2.step()) != DONE)
			error("[interner Fehler: %d]", rc);

		this.undo_stmt3.reset();
		this.undo_stmt3.bind_int64(1, (int64)pid);

		if((rc = this.undo_stmt3.step()) != DONE)
			error("[interner Fehler: %d]", rc);

		return true;
	}
	public bool add_stock(int32 user, uint64 product, int32 amount) {
		int rc;
		int64 timestamp = (new DateTime.now_utc()).to_unix();

		this.stock_stmt1.reset();
		this.stock_stmt1.bind_int(1, user);
		this.stock_stmt1.bind_int64(2, (int64)product);
		this.stock_stmt1.bind_int(3, amount);
		this.stock_stmt1.bind_int64(4, timestamp);

		if((rc = this.stock_stmt1.step()) != DONE)
			error("[interner Fehler: %d]", rc);

		this.stock_stmt2.reset();
		this.stock_stmt2.bind_int64(1, amount);
		this.stock_stmt2.bind_int64(2, (int64)product);

		if((rc = this.stock_stmt2.step()) != DONE)
			error("[interner Fehler: %d]", rc);

		return get_product_name(product, null);
	}
}
