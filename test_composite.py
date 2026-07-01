from PIL import Image
import os

trunk = Image.open('Arts/caylaunam/cay trong/apple.png').convert('RGBA')
foliage = Image.open('Arts/caylaunam/cay trong/apple4.png').convert('RGBA')

trunk_w, trunk_h = trunk.size
fol_w, fol_h = foliage.size

canvas_w, canvas_h = 300, 300
trunk_bottom_y = 250
trunk_center_x = canvas_w // 2

trunk_x = trunk_center_x - trunk_w // 2
trunk_y = trunk_bottom_y - trunk_h

offsets = [0, 20, 40, 60, 80, 100]

for offset in offsets:
    canvas = Image.new('RGBA', (canvas_w, canvas_h), (50, 150, 50, 255))
    canvas.paste(trunk, (trunk_x, trunk_y), trunk)
    
    fol_bottom_y = trunk_bottom_y - offset
    fol_y = fol_bottom_y - fol_h
    fol_x = trunk_center_x - fol_w // 2
    
    canvas.paste(foliage, (fol_x, fol_y), foliage)
    canvas.save(f'/Users/vuongquanghuy/.gemini/antigravity/brain/b608fb4a-dd14-4b26-9a96-9739afe86e23/composite_offset_{offset}.png')

print("Composites generated.")
