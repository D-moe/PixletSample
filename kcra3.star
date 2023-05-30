load("render.star", "render")
load("xpath.star", "xpath")
load("http.star", "http")

def fetch_data(url):
    item = None
    data = dict()
    STATUS_OK = 200
    resp = http.get(url)
    print(resp.status_code)
    if resp.status_code != STATUS_OK:
        fail("Request failed with status %d", resp.status_code)
    else:
        item = xpath.loads(resp.body()).query("/rss/channel/item/title")
        print("item: ", item)
    return item

def main():
    kcra = "https://www.kcra.com/topstories-rss"
    item = fetch_data(kcra)
    return render.Root(render.Marquee(
        width = 64,
        child = render.Text(item)
    ))