extends JsWeb3Node
class_name Wallet

signal wallet_connected(address: String)
signal wallet_disconnected
signal wallet_error(error: String)
signal balance_updated(balance: String)

var wallet_address: String = ""
var is_wallet_connected: bool = false
var accounts := []
var wallet_balance := 0
var popup_menu: Control
var wallet_address_label: Label

const SUPPORTED_CHAINS := {
	"ethereum": "0x1",  # Ethereum Mainnet
	"polygon": "0x89",  # Polygon Mainnet
	"Sei": "0x531",  # Sei Mainnet
	"Sei-devnet": "0xAE3F3",
	"Sei-testnet": "0x530"  # if you have it in your wallet
}

var connect_sequence: Sequence

func _ready():
	super._ready()
	create_popup_menu()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_X:
		toggle_popup()

# Creates a popup menu for wallet connection
func create_popup_menu():
	popup_menu = Control.new()
	popup_menu.set_anchors_preset(Control.PRESET_CENTER)
	popup_menu.set_size(Vector2(250, 120))
	popup_menu.modulate = Color(1, 1, 1, 1)  # White background
	popup_menu.visible = false

	var label = Label.new()
	label.text = "Connect Wallet?"
	label.add_theme_font_size_override("font_size", 20)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var button_yes = Button.new()
	button_yes.text = "Yes"
	button_yes.set_size(Vector2(100, 40))
	button_yes.position = Vector2(25, 60)
	button_yes.connect("pressed", _on_connect_wallet_pressed)

	var button_no = Button.new()
	button_no.text = "No"
	button_no.set_size(Vector2(100, 40))
	button_no.position = Vector2(130, 60)
	button_no.connect("pressed", _on_close_popup)

	# Wallet address label (hidden at first)
	wallet_address_label = Label.new()
	wallet_address_label.add_theme_font_size_override("font_size", 16)
	wallet_address_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wallet_address_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_address_label.visible = false

	# Add elements to menu
	popup_menu.add_child(label)
	popup_menu.add_child(button_yes)
	popup_menu.add_child(button_no)
	popup_menu.add_child(wallet_address_label)

	add_child(popup_menu)

func toggle_popup():
	popup_menu.visible = not popup_menu.visible

func _on_connect_wallet_pressed():
	connect_wallet()

func _on_close_popup():
	popup_menu.visible = false

func connect_wallet():
	if is_wallet_connected:
		print("Already connected.")
		return
	if not OS.has_feature("web"):
		emit_signal("wallet_error", "Wallet connection only available in web builds")
		return

	# Call JavaScript to connect MetaMask
	var script = "ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => accounts[0]).catch(console.error);"
	var result = JavaScriptBridge.eval(script)

	if result != null:
		wallet_address = result
		is_wallet_connected = true
		wallet_address_label.text = "Wallet: " + wallet_address
		wallet_address_label.visible = true
		popup_menu.visible = false
		emit_signal("wallet_connected", wallet_address)
	else:
		print("Wallet connection failed.")
