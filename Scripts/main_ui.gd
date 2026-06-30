extends CanvasLayer

const FONT_PATH := "res://Arts/UI/BIP.ttf"

const TEX_SHOP_BUTTON := "res://Arts/UI/main/iconshop.png"
const TEX_HOME_BUTTON := "res://Arts/UI/main/btn_home.png"
const TEX_HOME_ICON := "res://Arts/UI/main/icon_home.png"
const TEX_SETTING_BUTTON := "res://Arts/UI/main/btsetting.png"
const TEX_COIN := "res://Arts/UI/shop/iconcoins.png"
const TEX_DIAMOND := "res://Arts/UI/main/icondiamond.png"
const TEX_SHOP_BG := "res://Arts/UI/shop/bg.png"
const TEX_TAB_NORMAL := "res://Arts/UI/shop/bt1.png"
const TEX_TAB_ACTIVE := "res://Arts/UI/shop/bt2.png"
const TEX_ITEM_CARD := "res://Arts/UI/shop/bg1.png"
const TEX_NOTIFY := "res://Arts/UI/noti.png"
const UNLOCK_ALL_STORE_ITEMS_FOR_TEST := true

const CATEGORIES := [
	{
		"id": "factory",
		"name": "Nhà máy",
		"icon": "res://Arts/UI/shop/icon_shop-assets/Food_Processor.png",
	},
	{
		"id": "plants",
		"name": "Cây trồng",
		"icon": "res://Arts/UI/shop/icon_shop-assets/Plants.png",
	},
	{
		"id": "animals",
		"name": "Động vật",
		"icon": "res://Arts/UI/shop/icon_shop-assets/animals.png",
		"badge": 1,
	},
	{
		"id": "farms",
		"name": "Chuồng trại",
		"icon": "res://Arts/UI/shop/icon_shop-assets/Farms.png",
		"badge": 1,
	},
	{
		"id": "decor",
		"name": "Trang trí",
		"icon": "res://Arts/UI/shop/icon_shop-assets/deco.png",
	},
]

const SHOP_ITEMS := {
	"factory": [
		{"id": "bakery", "name": "Lò Bánh Mì", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Bakery.png", "scene": "res://Sence/Objects/Bakery/Bakery.tscn", "price": 20, "owned": "1/1", "locked": false},
		{"id": "food_processor", "name": "Máy Xay Thức Ăn", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Food Processor.png", "scene": "res://Sence/Objects/FoodProcessor/FoodProcessor.tscn", "price": 20, "owned": "1/1", "locked": false},
		{"id": "dairy", "name": "Xưởng Làm Bơ", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Dairy.png", "scene": "res://Sence/Objects/Dairy/Dairy.tscn", "price": 40, "owned": "1/1", "locked": false},
		{"id": "sugar_processor", "name": "Máy Làm Đường", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Sugar Processor.png", "scene": "res://Sence/Objects/SugarProcessor/SugarProcessor.tscn", "price": 80, "owned": "0/1", "locked": false, "new": true},
		{"id": "corn_oven", "name": "Xe Bắp Rang", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Corn Oven.png", "scene": "res://Sence/Objects/CornOven/CornOven.tscn", "level": 8, "owned": "0/1", "locked": true},
		{"id": "pie_bakery", "name": "Lò Nướng Bánh", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Pie Bakery.png", "scene": "res://Sence/Objects/PieBakery/PieBakery.tscn", "level": 14, "owned": "0/1", "locked": true},
		{"id": "roaster", "name": "Máy Rang", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Roaster.png", "scene": "res://Sence/Objects/Roaster/Roaster.tscn", "level": 18, "owned": "0/1", "locked": true},
		{"id": "sushi_shop", "name": "Sushi", "icon": "res://Arts/UI/shop/icon_nhamay-assets/Sushishop.png", "scene": "res://Sence/Objects/SushiShop/SushiShop.tscn", "level": 24, "owned": "0/1", "locked": true},
		{"id": "cake_bakery", "name": "Máy Bánh Kem", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Cake_Bakery.png", "scene": "res://Sence/Objects/CakeBakery/CakeBakery.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "coffee_machine", "name": "Máy Cà Phê", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Coffe_machine.png", "scene": "res://Sence/Objects/CoffeeMachine/CoffeeMachine.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "flower_factory", "name": "Xưởng Hoa", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/flower_factory.png", "scene": "res://Sence/Objects/FlowerFactory/FlowerFactory.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "goldsmith", "name": "Thợ Kim Hoàn", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Goldsmith.png", "scene": "res://Sence/Objects/Goldsmith/Goldsmith.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "hats", "name": "Xưởng Mũ", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/hats.png", "scene": "res://Sence/Objects/Hats/Hats.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "knitting_table", "name": "Bàn Dệt", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Knitting_Table.png", "scene": "res://Sence/Objects/KnittingTable/KnittingTable.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "paint_factory", "name": "Xưởng Sơn", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Paint_Factory.png", "scene": "res://Sence/Objects/PaintFactory/PaintFactory.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "paper_factory", "name": "Xưởng Giấy", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Paper_Factory.png", "scene": "res://Sence/Objects/PaperFactory/PaperFactory.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "sewing_table", "name": "Bàn May", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Sewing_table.png", "scene": "res://Sence/Objects/SewingTable/SewingTable.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "smelter", "name": "Lò Luyện Kim", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/smelter.png", "scene": "res://Sence/Objects/Smelter/Smelter.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "blender", "name": "Máy Xay Sinh Tố", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/blender.png", "scene": "res://Sence/Objects/Blender/Blender.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "candy_factory", "name": "Xưởng Kẹo", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/candy_factory.png", "scene": "res://Sence/Objects/CandyFactory/CandyFactory.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "cream_freezer", "name": "Máy Kem Lạnh", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Cream_Freezer.png", "scene": "res://Sence/Objects/CreamFreezer/CreamFreezer.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "jam_factory", "name": "Xưởng Mứt", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Jam_Factory.png", "scene": "res://Sence/Objects/JamFactory/JamFactory.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "juicer", "name": "Máy Ép Nước", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Juicer.png", "scene": "res://Sence/Objects/Juicer/Juicer.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "mexican_food", "name": "Đồ Ăn Mexico", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/Mexican_Food.png", "scene": "res://Sence/Objects/MexicanFood/MexicanFood.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "pizza_oven", "name": "Lò Pizza", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/pizza_oven.png", "scene": "res://Sence/Objects/PizzaOven/PizzaOven.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "wok", "name": "Chảo Wok", "icon": "res://Arts/Sprint2/Factory/icon_nhamay-assets/wok.png", "scene": "res://Sence/Objects/Wok/Wok.tscn", "price": 0, "owned": "0/1", "locked": false},
	],
	"plants": [
		{"name": "Táo", "icon": "res://Arts/UI/shop/icon_caytrong_shop/apple tree.png", "level": 15, "owned": "0/8", "locked": true},
		{"name": "Ca Cao", "icon": "res://Arts/UI/shop/icon_caytrong_shop/cacao tree.png", "level": 19, "owned": "0/8", "locked": true},
		{"name": "Anh Đào", "icon": "res://Arts/UI/shop/icon_caytrong_shop/cherry tree.png", "level": 22, "owned": "0/8", "locked": true},
		{"name": "Tử Đinh Hương", "icon": "res://Arts/UI/shop/icon_caytrong_shop/Lilac tree.png", "level": 26, "owned": "0/8", "locked": true},
		{"name": "Dâu Tây", "icon": "res://Arts/UI/shop/icon_caytrong_shop/Strawberry Bush tree.png", "level": 36, "owned": "0/8", "locked": true},
		{"name": "Hoa Hồng", "icon": "res://Arts/UI/shop/icon_caytrong_shop/rose tree.png", "level": 42, "owned": "0/8", "locked": true},
		{"name": "Ô Liu", "icon": "res://Arts/UI/shop/icon_caytrong_shop/golden daisy tree.png", "level": 57, "owned": "0/8", "locked": true},
	],
	"animals": [
		{"id": "chicken", "name": "Gà", "icon": "res://Arts/UI/shop/icon_animals-assets/chicken.png", "scene": "res://Sence/Objects/Chicken/Chicken.tscn", "animal_pen_type": "chicken", "price": 50, "owned": "4/4", "locked": false},
		{"id": "cow", "name": "Bò", "icon": "res://Arts/UI/shop/icon_animals-assets/cow.png", "scene": "res://Sence/Objects/Cow/Cow.tscn", "animal_pen_type": "cow", "price": 50, "owned": "2/4", "locked": false, "new": true},
		{"id": "pig", "name": "Heo", "icon": "res://Arts/UI/shop/icon_animals-assets/pig.png", "scene": "res://Sence/Objects/Pig/Pig.tscn", "animal_pen_type": "pig", "price": 0, "owned": "0/4", "locked": false},
		{"id": "sheep", "name": "Cừu", "icon": "res://Arts/UI/shop/icon_animals-assets/sheep.png", "scene": "res://Sence/Objects/Sheep/Sheep.tscn", "animal_pen_type": "sheep", "price": 0, "owned": "0/4", "locked": false},
		{"id": "bee", "name": "Ong", "icon": "res://Arts/UI/shop/icon_animals-assets/bee.png", "scene": "res://Sence/Objects/Bee/Bee.tscn", "animal_pen_type": "bee", "price": 0, "owned": "0/4", "locked": false},
		{"id": "ostrich", "name": "Đà Điểu", "icon": "res://Arts/UI/shop/icon_animals-assets/ostrich.png", "scene": "res://Sence/Objects/Ostrich/Ostrich.tscn", "animal_pen_type": "ostrich", "price": 0, "owned": "0/4", "locked": false},
		{"id": "peacock", "name": "Công", "icon": "res://Arts/UI/shop/icon_animals-assets/peacock.png", "scene": "res://Sence/Objects/Peacock/Peacock.tscn", "animal_pen_type": "peacock", "price": 0, "owned": "0/4", "locked": false},
		{"id": "henhouse", "name": "Chuồng Gà", "icon": "res://Arts/UI/shop/icon_chuong-assets/Henhouse.png", "scene": "res://Sence/Objects/Henhouse/Henhouse.tscn", "price": 5, "owned": "1/1", "locked": false},
		{"id": "cowshed", "name": "Chuồng Bò", "icon": "res://Arts/UI/shop/icon_chuong-assets/cowshed.png", "scene": "res://Sence/Objects/Cowshed/Cowshed.tscn", "price": 10, "owned": "1/1", "locked": false},
		{"id": "pigpen", "name": "Chuồng Heo", "icon": "res://Arts/UI/shop/icon_chuong-assets/Pigpen.png", "scene": "res://Sence/Objects/Pigpen/Pigpen.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "sheepfold", "name": "Chuồng Cừu", "icon": "res://Arts/UI/shop/icon_chuong-assets/Sheepfold.png", "scene": "res://Sence/Objects/Sheepfold/Sheepfold.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "beehive", "name": "Tổ Ong", "icon": "res://Arts/UI/shop/icon_chuong-assets/beehive.png", "scene": "res://Sence/Objects/Beehive/Beehive.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "ostrich_house", "name": "Nhà Đà Điểu", "icon": "res://Arts/UI/shop/icon_chuong-assets/Ostrich House.png", "scene": "res://Sence/Objects/OstrichHouse/OstrichHouse.tscn", "price": 0, "owned": "0/1", "locked": false},
		{"id": "peacock_house", "name": "Nhà Chim Công", "icon": "res://Arts/UI/shop/icon_chuong-assets/Peacock House.png", "scene": "res://Sence/Objects/PeacockHouse/PeacockHouse.tscn", "price": 0, "owned": "0/1", "locked": false},
	],
	"farms": [
		{"id": "crop_land", "name": "Ô Đất Trồng", "icon": "res://Arts/UI/shop/icon_chuong-assets/land.png", "scene": "res://Sence/Objects/CropLand/CropLand.tscn", "price": 1, "owned": "16/16", "locked": false},
		{"id": "wheat_seed", "name": "Hạt Lúa Mì", "icon": "res://Arts/caytrong-assets/hat_giong/Wheat.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "wheat", "price": 1, "owned": "0/99", "locked": false},
		{"id": "corn_seed", "name": "Hạt Ngô", "icon": "res://Arts/caytrong-assets/hat_giong/Corn.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "corn", "price": 2, "owned": "0/99", "locked": false},
		{"id": "carrot_seed", "name": "Hạt Cà Rốt", "icon": "res://Arts/caytrong-assets/hat_giong/Carrot.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "carrot", "price": 3, "owned": "0/99", "locked": false},
		{"id": "cabbage_seed", "name": "Hạt Bắp Cải", "icon": "res://Arts/caytrong-assets/hat_giong/Cabbage.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "cabbage", "price": 4, "owned": "0/99", "locked": false},
		{"id": "potato_seed", "name": "Hạt Khoai Tây", "icon": "res://Arts/caytrong-assets/hat_giong/Potato.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "potato", "price": 5, "owned": "0/99", "locked": false},
		{"id": "tomato_seed", "name": "Hạt Cà Chua", "icon": "res://Arts/caytrong-assets/hat_giong/Tomato.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "tomato", "price": 6, "owned": "0/99", "locked": false},
		{"id": "pumpkin_seed", "name": "Hạt Bí Ngô", "icon": "res://Arts/caytrong-assets/hat_giong/Pumpkin.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "pumpkin", "price": 7, "owned": "0/99", "locked": false},
		{"id": "rice_seed", "name": "Hạt Lúa", "icon": "res://Arts/caytrong-assets/hat_giong/Rice.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "rice", "price": 8, "owned": "0/99", "locked": false},
		{"id": "sugarcane_seed", "name": "Hạt Mía", "icon": "res://Arts/caytrong-assets/hat_giong/Sugarcane.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "sugarcane", "price": 9, "owned": "0/99", "locked": false},
		{"id": "beans_seed", "name": "Hạt Đậu", "icon": "res://Arts/caytrong-assets/hat_giong/Beans.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "beans", "price": 10, "owned": "0/99", "locked": false},
		{"id": "cotton_seed", "name": "Hạt Bông", "icon": "res://Arts/caytrong-assets/hat_giong/Cotton.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "cotton", "price": 11, "owned": "0/99", "locked": false},
		{"id": "pepper_seed", "name": "Hạt Ớt", "icon": "res://Arts/caytrong-assets/hat_giong/Pepper.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "pepper", "price": 12, "owned": "0/99", "locked": false},
		{"id": "sugar_beet_seed", "name": "Hạt Củ Cải Đường", "icon": "res://Arts/caytrong-assets/hat_giong/Sugar Beet.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "sugar_beet", "price": 13, "owned": "0/99", "locked": false},
		{"id": "strawbarry_seed", "name": "Hạt Dâu Tây", "icon": "res://Arts/caytrong-assets/hat_giong/Strawbarry.png", "scene": "res://Sence/Objects/SeedObject.tscn", "crop_id": "strawbarry", "price": 14, "owned": "0/99", "locked": false},
	],
	"decor": [
		{"id": "bicycle", "name": "Xe Đạp", "icon": "res://Arts/UI/decor/decor/icondecor_shop/bicycle.png", "scene": "res://Sence/Objects/Bicycle/Bicycle.tscn", "price": 25, "owned": "0/8", "locked": false},
		{"id": "lamp", "name": "Đèn", "icon": "res://Arts/UI/decor/decor/icondecor_shop/lamp.png", "scene": "res://Sence/Objects/Lamp/Lamp.tscn", "price": 30, "owned": "0/8", "locked": false},
		{"name": "Ghế Đu", "icon": "res://Arts/UI/decor/decor/icondecor_shop/rocking chair.png", "level": 12, "owned": "0/8", "locked": true},
		{"name": "Bụi Hồng", "icon": "res://Arts/UI/decor/decor/icondecor_shop/rose bush.png", "level": 16, "owned": "0/8", "locked": true},
		{"name": "Bù Nhìn", "icon": "res://Arts/UI/decor/decor/icondecor_shop/scarecrow.png", "level": 22, "owned": "0/8", "locked": true},
		{"name": "Vọng Lâu", "icon": "res://Arts/UI/decor/decor/icondecor_shop/gazebo.png", "level": 28, "owned": "0/8", "locked": true},
	],
}

var _hud_root: Control
var _shop_screen: Control
var _item_grid: GridContainer
var _tab_buttons: Dictionary = {}
var _selected_category_id := "factory"
var _ui_font: Font
var _placement_manager: PlacementManager
var _animation_controls: Panel
var _animation_target: Node
var _idle_button: Button
var _active_button: Button


func _ready() -> void:
	layer = 20
	_placement_manager = get_parent().get_node_or_null("PlacementManager") as PlacementManager
	_ui_font = load(FONT_PATH) as Font
	_build_hud()
	_build_shop_screen()
	get_viewport().size_changed.connect(_update_shop_grid_columns)


func show_shop() -> void:
	_shop_screen.visible = true
	_hud_root.visible = false
	_select_category(_selected_category_id)


func hide_shop() -> void:
	_shop_screen.visible = false
	_hud_root.visible = true


func is_shop_open() -> bool:
	return _shop_screen.visible


func show_animation_controls(target: Node) -> void:
	_animation_target = target
	if _animation_controls == null:
		return

	var can_show := (
		target != null
		and target.has_method("has_factory_animation")
		and bool(target.call("has_factory_animation"))
	)
	_animation_controls.visible = can_show
	if can_show:
		_set_animation_button_state(str(target.call("get_factory_animation_mode")))


func hide_animation_controls() -> void:
	_animation_target = null
	if _animation_controls != null:
		_animation_controls.visible = false


func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.name = "Hud"
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hud_root)

	var currency_row := HBoxContainer.new()
	currency_row.name = "Currency"
	currency_row.alignment = BoxContainer.ALIGNMENT_END
	currency_row.add_theme_constant_override("separation", 12)
	_pin(currency_row, 0.62, 0.0, 1.0, 0.0, 0, 14, -18, 70)
	_hud_root.add_child(currency_row)
	currency_row.add_child(_make_currency_pill(TEX_COIN, "11"))
	currency_row.add_child(_make_currency_pill(TEX_DIAMOND, "28"))

	var left_nav := HBoxContainer.new()
	left_nav.name = "LeftNav"
	left_nav.add_theme_constant_override("separation", 12)
	_pin(left_nav, 0.0, 1.0, 0.0, 1.0, 28, -98, 220, -22)
	_hud_root.add_child(left_nav)
	var home_button := _make_icon_button(TEX_HOME_BUTTON, Vector2(74, 74), "HomeButton")
	var home_icon := _make_texture(TEX_HOME_ICON, Vector2(42, 42))
	home_icon.name = "HomeIcon"
	home_icon.position = Vector2(16, 17)
	home_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_button.add_child(home_icon)
	left_nav.add_child(home_button)
	left_nav.add_child(_make_icon_button(TEX_SETTING_BUTTON, Vector2(74, 74), "SettingsButton"))

	var shop_button := _make_icon_button(TEX_SHOP_BUTTON, Vector2(86, 86), "ShopButton")
	_pin(shop_button, 1.0, 1.0, 1.0, 1.0, -112, -112, -26, -26)
	shop_button.pressed.connect(show_shop)
	_hud_root.add_child(shop_button)

	var notify := _make_texture(TEX_NOTIFY, Vector2(30, 30))
	notify.name = "ShopNotify"
	notify.position = Vector2(58, 2)
	notify.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_button.add_child(notify)

	var notify_label := _make_label("!", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	notify_label.add_theme_constant_override("outline_size", 3)
	notify_label.add_theme_color_override("font_outline_color", Color(0.55, 0.0, 0.05))
	notify_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	notify.add_child(notify_label)

	_build_animation_controls()


func _build_animation_controls() -> void:
	_animation_controls = Panel.new()
	_animation_controls.name = "AnimationControls"
	_animation_controls.visible = false
	_animation_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	_animation_controls.add_theme_stylebox_override("panel", _round_style(Color(0.20, 0.17, 0.13, 0.92), Color(1.0, 0.75, 0.32), 2, 8))
	_pin(_animation_controls, 0.5, 1.0, 0.5, 1.0, -132, -104, 132, -48)
	_hud_root.add_child(_animation_controls)

	var row := HBoxContainer.new()
	row.name = "ModeButtons"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_top = 8
	row.offset_right = -8
	row.offset_bottom = -8
	_animation_controls.add_child(row)

	_idle_button = _make_animation_mode_button("Idle")
	_idle_button.name = "IdleButton"
	_idle_button.pressed.connect(_play_animation_mode.bind("idle"))
	row.add_child(_idle_button)

	_active_button = _make_animation_mode_button("Active")
	_active_button.name = "ActiveButton"
	_active_button.pressed.connect(_play_animation_mode.bind("active"))
	row.add_child(_active_button)


func _build_shop_screen() -> void:
	_shop_screen = Control.new()
	_shop_screen.name = "ShopScreen"
	_shop_screen.visible = false
	_shop_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shop_screen)

	var bg_color := ColorRect.new()
	bg_color.name = "WarmBackground"
	bg_color.color = Color(0.87, 0.48, 0.17)
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop_screen.add_child(bg_color)

	var bg_texture := _make_texture(TEX_SHOP_BG, Vector2.ZERO)
	bg_texture.name = "ShopBackground"
	bg_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_shop_screen.add_child(bg_texture)

	var header := ColorRect.new()
	header.name = "Header"
	header.color = Color(0.98, 0.64, 0.31)
	_pin(header, 0.0, 0.0, 1.0, 0.0, 0, 0, 0, 82)
	_shop_screen.add_child(header)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "<"
	back_button.custom_minimum_size = Vector2(58, 58)
	back_button.add_theme_font_size_override("font_size", 36)
	back_button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.56))
	back_button.add_theme_stylebox_override("normal", _round_style(Color(0.95, 0.44, 0.12), Color(0.56, 0.25, 0.07), 3, 29))
	back_button.add_theme_stylebox_override("hover", _round_style(Color(1.0, 0.55, 0.17), Color(0.56, 0.25, 0.07), 3, 29))
	back_button.add_theme_stylebox_override("pressed", _round_style(Color(0.82, 0.34, 0.09), Color(0.56, 0.25, 0.07), 3, 29))
	back_button.pressed.connect(hide_shop)
	_pin(back_button, 0.0, 0.0, 0.0, 0.0, 52, 12, 110, 70)
	_shop_screen.add_child(back_button)

	var title := _make_label("CỬA HÀNG", 34, Color(0.33, 0.19, 0.05), HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "ShopTitle"
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.86, 0.43))
	_pin(title, 0.0, 0.0, 0.0, 0.0, 124, 18, 440, 72)
	_shop_screen.add_child(title)

	var header_currency := HBoxContainer.new()
	header_currency.alignment = BoxContainer.ALIGNMENT_END
	header_currency.add_theme_constant_override("separation", 12)
	_pin(header_currency, 0.60, 0.0, 1.0, 0.0, 0, 14, -28, 68)
	_shop_screen.add_child(header_currency)
	header_currency.add_child(_make_currency_pill(TEX_COIN, "11"))
	header_currency.add_child(_make_currency_pill(TEX_DIAMOND, "28"))

	var tab_rail := Panel.new()
	tab_rail.name = "CategoryRail"
	tab_rail.add_theme_stylebox_override("panel", _round_style(Color(0.54, 0.25, 0.09, 0.92), Color(0.32, 0.14, 0.04), 0, 18))
	_pin(tab_rail, 0.0, 0.0, 0.0, 1.0, 50, 112, 246, -72)
	_shop_screen.add_child(tab_rail)

	var tab_column := VBoxContainer.new()
	tab_column.name = "CategoryTabs"
	tab_column.add_theme_constant_override("separation", -8)
	_pin(tab_column, 0.0, 0.0, 0.0, 1.0, 18, 20, 196, -20)
	tab_rail.add_child(tab_column)

	for category in CATEGORIES:
		var tab := _make_category_tab(category)
		tab_column.add_child(tab)
		_tab_buttons[category.id] = tab

	var content_clip := Panel.new()
	content_clip.name = "ItemArea"
	content_clip.add_theme_stylebox_override("panel", _round_style(Color(0.74, 0.36, 0.12, 0.20), Color.TRANSPARENT, 0, 8))
	_pin(content_clip, 0.0, 0.0, 1.0, 1.0, 280, 104, -34, -34)
	_shop_screen.add_child(content_clip)

	var scroll := ScrollContainer.new()
	scroll.name = "ItemScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_clip.add_child(scroll)

	_item_grid = GridContainer.new()
	_item_grid.name = "ItemGrid"
	_item_grid.add_theme_constant_override("h_separation", 28)
	_item_grid.add_theme_constant_override("v_separation", 24)
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_grid)
	_select_category(_selected_category_id)
	_update_shop_grid_columns()


func _make_category_tab(category: Dictionary) -> TextureButton:
	var button := TextureButton.new()
	button.name = "%sTab" % category.id.capitalize()
	button.custom_minimum_size = Vector2(178, 92)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_normal = _load_texture(TEX_TAB_ACTIVE)
	button.texture_hover = _load_texture(TEX_TAB_NORMAL)
	button.texture_pressed = _load_texture(TEX_TAB_NORMAL)
	button.pressed.connect(_select_category.bind(category.id))

	var icon := _make_texture(category.icon, Vector2(86, 66))
	icon.name = "Icon"
	icon.position = Vector2(46, 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	if category.has("badge"):
		var badge := Panel.new()
		badge.name = "Badge"
		badge.position = Vector2(150, 17)
		badge.size = Vector2(34, 34)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _round_style(Color(0.92, 0.02, 0.16), Color(0.55, 0.0, 0.07), 2, 17))
		button.add_child(badge)

		var badge_label := _make_label(str(category.badge), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		badge_label.add_theme_constant_override("outline_size", 3)
		badge_label.add_theme_color_override("font_outline_color", Color(0.45, 0.0, 0.03))
		badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.add_child(badge_label)

	return button


func _select_category(category_id: String) -> void:
	_selected_category_id = category_id
	for tab_id in _tab_buttons:
		var tab := _tab_buttons[tab_id] as TextureButton
		tab.texture_normal = _load_texture(TEX_TAB_NORMAL if tab_id == category_id else TEX_TAB_ACTIVE)
		tab.modulate = Color(0.55, 0.80, 1.0) if tab_id == category_id else Color.WHITE

	if _item_grid == null:
		return

	for child in _item_grid.get_children():
		child.queue_free()

	for item in SHOP_ITEMS.get(category_id, []):
		_item_grid.add_child(_make_item_card(item))

	_update_shop_grid_columns()


func _make_item_card(item: Dictionary) -> Control:
	var is_locked := _is_item_locked(item)
	var card := Panel.new()
	card.name = "%sCard" % str(item.name).replace(" ", "")
	card.custom_minimum_size = Vector2(180, 230)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _round_style(Color(0.81, 0.76, 0.56), Color(0.55, 0.48, 0.31), 4, 10))
	if not is_locked:
		card.gui_input.connect(_on_item_card_gui_input.bind(item))

	var title := _make_label(item.name, 14, Color(0.46, 0.38, 0.24), HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pin(title, 0.0, 0.0, 1.0, 0.0, 10, 6, -10, 48)
	card.add_child(title)

	var icon := _make_texture(item.icon, Vector2(124, 98))
	icon.name = "ItemIcon"
	icon.position = Vector2(28, 46)
	icon.modulate = Color(0.58, 0.58, 0.58) if is_locked else Color.WHITE
	card.add_child(icon)

	var owned := _make_label(item.get("owned", ""), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	owned.add_theme_constant_override("outline_size", 4)
	owned.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
	_pin(owned, 0.0, 0.0, 1.0, 0.0, 14, 128, -14, 154)
	card.add_child(owned)

	if item.get("new", false):
		var ribbon := Panel.new()
		ribbon.name = "NewBadge"
		ribbon.position = Vector2(140, 0)
		ribbon.size = Vector2(40, 40)
		ribbon.add_theme_stylebox_override("panel", _round_style(Color(0.95, 0.02, 0.22), Color.WHITE, 3, 20))
		card.add_child(ribbon)

		var new_label := _make_label("MỚI", 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		new_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		ribbon.add_child(new_label)

	var buy_bar := Panel.new()
	buy_bar.name = "BuyBar"
	buy_bar.add_theme_stylebox_override("panel", _round_style(
		Color(0.08, 0.75, 0.93) if not is_locked else Color(0.50, 0.53, 0.55),
		Color(0.20, 0.23, 0.25),
		2,
		8
	))
	_pin(buy_bar, 0.0, 0.0, 1.0, 0.0, 16, 170, -16, 214)
	card.add_child(buy_bar)

	if is_locked:
		var lock_label := _make_label("LV.%d" % item.get("level", 1), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		lock_label.add_theme_constant_override("outline_size", 4)
		lock_label.add_theme_color_override("font_outline_color", Color(0.06, 0.07, 0.08))
		lock_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		buy_bar.add_child(lock_label)
	else:
		var price_row := HBoxContainer.new()
		price_row.alignment = BoxContainer.ALIGNMENT_CENTER
		price_row.add_theme_constant_override("separation", 8)
		price_row.set_anchors_preset(Control.PRESET_FULL_RECT)
		buy_bar.add_child(price_row)
		price_row.add_child(_make_texture(TEX_COIN, Vector2(28, 28)))

		var price := _make_label(str(item.get("price", 0)), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		price.add_theme_constant_override("outline_size", 4)
		price.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
		price.custom_minimum_size = Vector2(54, 34)
		price_row.add_child(price)

	return card


func _on_item_card_gui_input(event: InputEvent, item: Dictionary) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_viewport().set_input_as_handled()
			_start_build_from_item(item)


func _start_build_from_item(item: Dictionary) -> void:
	if _is_item_locked(item):
		return

	if _placement_manager == null:
		push_warning("Không tìm thấy PlacementManager để xây item: %s" % item.get("name", "unknown"))
		return

	var spawned_obj := _placement_manager.start_build_from_shop_item(item)
	if spawned_obj != null:
		hide_shop()


func _is_item_locked(item: Dictionary) -> bool:
	if UNLOCK_ALL_STORE_ITEMS_FOR_TEST:
		return false

	return item.get("locked", false)


func _make_animation_mode_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(112, 40)
	button.add_theme_font_size_override("font_size", 18)
	if _ui_font != null:
		button.add_theme_font_override("font", _ui_font)
	return button


func _play_animation_mode(mode_name: String) -> void:
	if _animation_target == null or not is_instance_valid(_animation_target):
		hide_animation_controls()
		return

	if _animation_target.has_method("play_factory_animation"):
		_animation_target.call("play_factory_animation", mode_name)
		_set_animation_button_state(mode_name)


func _set_animation_button_state(mode_name: String) -> void:
	if _idle_button == null or _active_button == null:
		return

	_style_animation_button(_idle_button, mode_name == "idle")
	_style_animation_button(_active_button, mode_name == "active")


func _style_animation_button(button: Button, active: bool) -> void:
	var fill := Color(0.96, 0.55, 0.14) if active else Color(0.42, 0.33, 0.25)
	var border := Color(1.0, 0.86, 0.42) if active else Color(0.25, 0.20, 0.16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_color_override("font_outline_color", Color(0.15, 0.09, 0.04))
	button.add_theme_stylebox_override("normal", _round_style(fill, border, 2, 8))
	button.add_theme_stylebox_override("hover", _round_style(fill.lightened(0.08), border, 2, 8))
	button.add_theme_stylebox_override("pressed", _round_style(fill.darkened(0.08), border, 2, 8))


func _make_currency_pill(icon_path: String, value: String) -> Control:
	var pill := Panel.new()
	pill.custom_minimum_size = Vector2(154, 46)
	pill.add_theme_stylebox_override("panel", _round_style(Color(0.28, 0.15, 0.08, 0.96), Color(0.54, 0.28, 0.10), 2, 23))

	var icon := _make_texture(icon_path, Vector2(46, 46))
	icon.position = Vector2(-8, 0)
	pill.add_child(icon)

	var value_label := _make_label(value, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.add_theme_constant_override("outline_size", 4)
	value_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02))
	_pin(value_label, 0.0, 0.0, 1.0, 1.0, 42, 6, -44, -6)
	pill.add_child(value_label)

	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(34, 34)
	plus.add_theme_font_size_override("font_size", 24)
	plus.add_theme_color_override("font_color", Color.WHITE)
	plus.add_theme_stylebox_override("normal", _round_style(Color(0.95, 0.42, 0.12), Color(1.0, 0.86, 0.52), 2, 17))
	plus.add_theme_stylebox_override("hover", _round_style(Color(1.0, 0.54, 0.17), Color(1.0, 0.86, 0.52), 2, 17))
	plus.add_theme_stylebox_override("pressed", _round_style(Color(0.78, 0.31, 0.08), Color(1.0, 0.86, 0.52), 2, 17))
	_pin(plus, 1.0, 0.0, 1.0, 0.0, -38, 6, -4, 40)
	pill.add_child(plus)

	return pill


func _make_icon_button(texture_path: String, button_size: Vector2, node_name: String) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.custom_minimum_size = button_size
	button.size = button_size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = _load_texture(texture_path)
	button.texture_hover = _load_texture(texture_path)
	button.texture_pressed = _load_texture(texture_path)
	return button


func _make_texture(texture_path: String, texture_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = _load_texture(texture_path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if texture_size != Vector2.ZERO:
		texture_rect.custom_minimum_size = texture_size
		texture_rect.size = texture_size
	return texture_rect


func _make_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	if _ui_font != null:
		label.add_theme_font_override("font", _ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _round_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _pin(control: Control, anchor_left: float, anchor_top: float, anchor_right: float, anchor_bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = anchor_left
	control.anchor_top = anchor_top
	control.anchor_right = anchor_right
	control.anchor_bottom = anchor_bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom


func _update_shop_grid_columns() -> void:
	if _item_grid == null:
		return

	var viewport_width := float(get_viewport().get_visible_rect().size.x)
	var content_width := maxf(360.0, viewport_width - 330.0)
	_item_grid.columns = clampi(int(content_width / 208.0), 2, 4)


func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("Không tìm thấy texture UI: %s" % path)
		return null
	return load(path) as Texture2D
