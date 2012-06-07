[Compact]
public class Sale {
	public int64 timestamp;
	public int64 article;
	public int32 user;
	public string product_name;

	public Sale(int32 user, int64 article, int64 timestamp) {
		this.user = user;
		this.article = article;
		this.timestamp = timestamp;
	}
}
