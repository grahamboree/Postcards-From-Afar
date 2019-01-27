# -*- coding: utf-8 -*-

import sys
from math import *

# order corresponds to the order in font.inc
char_list = [
    ' ', '!', '?', '"', "'", ',', '.', '0', '1', '2', '3', '4', '5', '6', '7', '8',
    '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e',
    'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u',
    'v', 'w', 'x', 'y', 'z'
]

# ’
name = "INTRO"
text = u"You're about to spend 4 months traveling through Africa, just because you want to. You've spent a lot of time planning, packing, and taking care of your immunization. While you're over there, your partner is moving across the country and beginning grad school. The two of you decide to keep each other updated on this stage of your life through a series of postcards. As you sit on the plane in Boston, you can't help but feel a bit nervous. At least your arms don't hurt anymore from the seven shots."

text.replace('  ', ' ')
text.replace(u'’', u"'")

width = 20
height = 18

def line_len(words):
    if len(words) == 0:
        return 0
    # spaces
    count = len(words) - 1
    for word in words:
        count = count + len(word)
    return count

lines = []
cur_line = []

for word in text.split():
    # 1 here for a space
    new_len = line_len(cur_line) + 1 + len(word)

    if new_len <= width:
        # there's still space in this line
        cur_line.append(word)
    else:
        lines.append(' '.join(cur_line))
        cur_line = [word]

if len(cur_line) > 0:
    lines.append(' '.join(cur_line))

# pad each line out with spaces
lines = [l + ' ' * (width - len(l)) for l in lines]

pages = [lines[x:x+18] for x in xrange(0, len(lines), 18)]

print '\n\nSection "TEXT_' + name + '", ROMX, BANK[2]'
for idx, page in enumerate(pages):
    print ''

    # pad out the page with empty lines if necessary
    for i in range(height - len(page)):
        page.append(' ' * width)

    page_name = "TEXT_" + name + str(idx)

    print page_name + ':'
    for line in page:
        indexes = ['$' + format(char_list.index(c), '02x') for c in line]
        print '    DB ' + ','.join(indexes)




