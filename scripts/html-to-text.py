"""Convert Confluence-exported HTML to readable plain text. Usage: python html-to-text.py <file.html>"""
import sys, html
from html.parser import HTMLParser

class Cleaner(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skip = 0
        self.list_depth = 0
        self.in_td = False
        self.first_cell = True
        self.heading = None

    def handle_starttag(self, tag, attrs):
        if tag in ('style','script','head'):
            self.skip += 1
        elif tag in ('h1','h2','h3','h4','h5','h6'):
            self.heading = tag
            self.out.append('\n\n' + '#'*int(tag[1]) + ' ')
        elif tag == 'li':
            self.out.append('\n' + '  '*self.list_depth + '- ')
        elif tag in ('ul','ol'):
            self.list_depth += 1
        elif tag == 'p':
            self.out.append('\n')
        elif tag == 'br':
            self.out.append('\n')
        elif tag == 'tr':
            self.out.append('\n')
            self.first_cell = True
        elif tag in ('td','th'):
            if not self.first_cell:
                self.out.append(' | ')
            else:
                self.out.append('  ')
            self.first_cell = False
            self.in_td = True
        elif tag == 'hr':
            self.out.append('\n\n---\n')

    def handle_endtag(self, tag):
        if tag in ('style','script','head'):
            self.skip = max(0, self.skip - 1)
        elif tag in ('h1','h2','h3','h4','h5','h6'):
            self.heading = None
        elif tag in ('ul','ol'):
            self.list_depth = max(0, self.list_depth - 1)
        elif tag in ('td','th'):
            self.in_td = False

    def handle_data(self, data):
        if self.skip:
            return
        text = data.replace('\xa0',' ')
        if not text.strip() and '\n' in text:
            return
        self.out.append(text)

    def text(self):
        s = ''.join(self.out)
        # collapse 3+ newlines
        import re
        s = re.sub(r'\n{3,}', '\n\n', s)
        s = re.sub(r'[ \t]+\n', '\n', s)
        return s.strip()

if __name__ == '__main__':
    path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else None
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        data = f.read()
    p = Cleaner()
    p.feed(data)
    text = p.text()
    if out_path:
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(text)
    else:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        print(text)
