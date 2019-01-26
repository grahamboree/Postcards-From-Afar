import sys

# order corresponds to the order in font.inc
char_list = [
    ' ', '!', '?', '"', "'", ',', '.', '0', '1', '2', '3', '4', '5', '6', '7', '8',
    '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e',
    'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
    'v', 'w', 'x', 'y', 'z'
]

#text_file = sys.argv[1]
#with open(text_file) as f:
#    text = f.read()

text = "This is a second page of text that is different from the first and needs to be paginated!"

# screen is 20x18 but we want a border
max_width = 20
window_width = 32

def line_len(words):
    if len(words) == 0:
        return 0
    # spaces
    count = len(words) - 1
    for word in words:
        count = count + len(word)
    return count

empty_line = ' ' * 32
lines = []
cur_line = []

for word in text.split():
    # 1 here for a space
    new_len = line_len(cur_line) + 1 + len(word)

    if new_len < max_width:
        # there's still space in this line
        cur_line.append(word)
    else:
        lines.append(' '.join(cur_line))
        cur_line = [word]

if len(cur_line) > 0:
    lines.append(' '.join(cur_line))

lines = [l + ' ' * (32 - len(l)) for l in lines]

for i in range(32 - len(lines)):
    lines.append(empty_line)

for line in lines:
    indexes = ['$' + format(char_list.index(c), '02x') for c in line]
    print 'DB ' + ','.join(indexes)
