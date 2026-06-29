MainHouseSample_Fixed

Cách dùng:
1. Giải nén toàn bộ thư mục vào gốc project Godot.
2. Mở res://Scenes/Objects/MainHouse.tscn.
3. Nếu ảnh nhà chưa khớp chân ô, chỉnh Sprite2D > Position.
4. Trong base.tscn cần có các node: GroundLayer, BlockLayer, Objects.
5. Xem base_usage_example.gd để biết cách spawn nhà.

Lưu ý:
- MainHouse.tscn chỉ chứa hình ảnh + size_in_cells = Vector2i(4, 4).
- Logic đặt nhà, kiểm tra vùng 4x4, occupied_cells vẫn nằm ở base.gd.
