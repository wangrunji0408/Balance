import cv2
import numpy as np

def colorToType (color):
	code = color[0] | (color[1] << 8) | (color[2] << 16)
	ct = {
		# rgb: id
		0x000000: 0,
		0xccffff: 1,
		0xff9900: 2,
		0x996600: 3,
		0x66ffff: 4,
		0xcc9900: 5,
		0x333399: 6,
		0xffff00: 7,
		0xff0000: 8,
		0x333333: 9,
		0x33ff33: 10,
		0x33ff66: 11,
		0x33ff99: 12,
		0x33ffcc: 13,
		0xff0033: 14,
		0xff0066: 15,
		0xff0099: 16,
		0xff00cc: 17,
		0x66ccff: 18,
		0xcccc00: 19,
		0x336699: 20,
		0x3300ff: 21,
		0x3333ff: 22,
		0xffffff: 1,
	}
	if code != 0 and ct.get(code, 0) == 0:
		print('undefined color: ', color)
	return ct.get(code, 0)

width = 6
image = cv2.imread('./maps/5.png')
(m, n, _) = image.shape
mif = open('map.mif', 'w')
mif.write('-- Generated by MakeMif.py\n\n')
mif.writelines(['WIDTH=%d;\n' % width, 'DEPTH=%d;\n' % (64*64), 'ADDRESS_RADIX=HEX;\n', 'DATA_RADIX=HEX;\n'])
mif.write('\n')
mif.write('CONTENT BEGIN\n')
k = 0
for i in range(64):
	for j in range(64):
		t = colorToType( image[i, j] ) if i < m and j < n else 0
		mif.write('\t%03X : %x;\n' % (k, t))
		k += 1
mif.write('END;\n')
