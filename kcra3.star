load("render.star", "render")
load("xpath.star", "xpath")
load("http.star", "http")
load("cache.star", "cache")

def fetch_url(url):
    STATUS_OK = 200
    resp = http.get(url)
    print("STATUS: ", resp.status_code)
    if resp.status_code != STATUS_OK:
        fail("Request failed with status %d", resp.status_code)
    return resp

def to_multiline(text):
    new_string = ""
    # Print the string if we reach the max line sizing,
    # or when we reach a space
    index = 0
    # From default font size
    char_px = 5
    curr_word = ""

    for i in range(len(text)):
        char = text[i]
        if char !=  ' ':
            curr_word = curr_word + char
            index = index + 1
        else:
            # Want to make sure we won't overflow the line
            if (index + len(curr_word) + 1) * char_px > 64:
                # Print on next line
                new_string = new_string + "\n" + curr_word + " "
                index = len(curr_word) + 1
                # Should we split words over 12 characters, probably?
                # Think about this
            else:
                new_string = new_string + " " + curr_word
                index = len(curr_word) + 1
            curr_word = ""
    new_string = new_string + "\n" + curr_word
    return new_string

def fetch_data(url):
    stories = []
    # First check the cache
    resp = cache.get("data_kcra")
    if resp == None:
        resp = fetch_url(url).body()
        cache.set("data_kcra", resp, ttl_seconds = 600)
        print("Refetching data from kcra3")
    data = xpath.loads(resp)
    nodes = data.query_all_nodes("/rss/channel/item")
    for node in nodes:
        story = dict()
        story['title'] = node.query("/title")
        print("The title is ",node.query("/title"))
        # Chop paragraph tags off description
        story['description'] = to_multiline(node.query("/description")[3:-4])
        # We want to split the description based on the font size,
        # into multiple lines. The default font size takes 5 pixels
        # across
        # We also want to make sure not to split on word boundaries if possible.
        story['link'] = node.query("/link")
        stories.append(story)
    return stories

def main():
    kcra = "https://www.kcra.com/topstories-rss"
    index = cache.get("index_kcra")
    if index == None:
        index = 0
        print("Cache expired")
    index = int(index)
    stories = fetch_data(kcra)
    curr_story = 0
    if index == len(stories)- 1:
        index = 0
    else:
        index = index + 1
    cache.set("index_kcra", str(index), ttl_seconds = 600)
    return render.Root(
        child =
                 render.Column(
                    children = [
                        render.Box(width = 64, height = 16, color="#300", child = render.Marquee(width = 48, height = 16, child = render.Text(stories[index]["title"], color="#900"))),
                        render.Box(width = 64, height = 16, color="#333", child = render.Marquee(width = 64, height = 16, scroll_direction = 'vertical', child = render.WrappedText(stories[index]["description"])))
                    ])
   )