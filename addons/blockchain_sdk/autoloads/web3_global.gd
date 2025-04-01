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
var wallet_address_label: Label  # Store the label for the address

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

# Creates a simple popup menu with a white background and text
func create_popup_menu():
	popup_menu = Control.new()
	popup_menu.set_anchors_preset(Control.PRESET_CENTER)
	popup_menu.set_size(Vector2(200, 100))
	popup_menu.modulate = Color(1, 1, 1, 1)  # White background
	popup_menu.visible = false

	var label = Label.new()
	label.text = "Connect Wallet?"
	label.add_theme_font_size_override("font_size", 20)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.set_alignment(HORIZONTAL_ALIGNMENT_CENTER)

	var button_yes = Button.new()
	button_yes.text = "Yes"
	button_yes.rect_min_size = Vector2(80, 30)
	button_yes.connect("pressed", self, "_on_yes_pressed")
	
	var button_no = Button.new()
	button_no.text = "No"
	button_no.rect_min_size = Vector2(80, 30)
	button_no.connect("pressed", self, "_on_no_pressed")
	
	button_yes.set_anchors_preset(Control.PRESET_CENTER)
	button_no.set_anchors_preset(Control.PRESET_CENTER)
	
	# Layout buttons in the popup
	button_yes.rect_position = Vector2(40, 50)  # position the button inside the menu
	button_no.rect_position = Vector2(40, 80)
	
	popup_menu.add_child(label)
	popup_menu.add_child(button_yes)
	popup_menu.add_child(button_no)

	add_child(popup_menu)

# Toggles the popup menu visibility
func toggle_popup():
	popup_menu.visible = not popup_menu.visible

# What happens if the user clicks "Yes"
func _on_yes_pressed():
	connect_wallet()  # This calls the wallet connection logic
	popup_menu.visible = false  # Hide the popup menu after selection

# What happens if the user clicks "No"
func _on_no_pressed():
	popup_menu.visible = false  # Just hide the popup menu if "No" is selected

## Disconnect from the account
func disconnect_wallet() -> void:
	wallet_address = ""
	is_wallet_connected = false
	emit_signal("wallet_disconnected")
	accounts.clear()

## Connect to the account
func connect_wallet() -> void:
	if is_wallet_connected:
		print("Already connecting to wallet. Please wait.")
		return
	if not OS.has_feature("web"):
		emit_signal("wallet_error", "Wallet connection only available in web builds")
		return
	is_wallet_connected = true
	reconnect()

func reconnect():
	connect_sequence = Sequence.new(_on_reconnect, on_reject)
	connect_sequence.runasynic(
		window.ethereum.request(
			create_jsobj({
				"method": "wallet_requestPermissions",
				"params": [{"eth_accounts": {}}]
			})
		)
	)

func _on_reconnect(response):
	connect_sequence.update(set_accounts)
	connect_sequence.runasynic(
		window.ethereum.request(
			create_jsobj({"method": "eth_requestAccounts"})
		)
	)

## Setter function (accounts)
func set_accounts(response_array):
	accounts.clear()
	for i in range(response_array.length):
		accounts.push_back(response_array[i])
	if accounts.size():
		wallet_address = accounts[0]
		is_wallet_connected = true
		emit_signal("wallet_connected", accounts[0])
		print(accounts)
		display_wallet_address()  # This now displays the wallet address on the screen
		get_balance()
		switch_network("Sei-devnet")
		connect_sequence.update(initialize_signer)
		connect_sequence.runasynic(provider.getSigner())

# Display the wallet address on screen
func display_wallet_address():
	if not wallet_address_label:
		# Create the label to display the wallet address if it doesn't exist
		wallet_address_label = Label.new()
		wallet_address_label.add_theme_font_size_override("font_size", 18)
		wallet_address_label.set_anchors_preset(Control.PRESET_TOP_CENTER)
		wallet_address_label.rect_position = Vector2(0, 20)
		add_child(wallet_address_label)  # Add the label to the root node

	# Update the label text with the wallet address
	wallet_address_label.text = "Connected: " + wallet_address

## Get current wallet balance
func get_balance() -> void:
	if not is_wallet_connected:
		emit_signal("connection_failed", "Wallet not connected")  # doesn't exist fix
		return
	var balance_sequence = Sequence.new(
		func(response):
		var balance = divide_by_pow10(hex_to_decimal_str(response)).pad_decimals(4)
		wallet_balance = balance.to_float()
		emit_signal("balance_updated", balance),
		on_reject,
		true
	)
	balance_sequence.runasynic(
		window.ethereum.request(
			create_jsobj({ 
				"method": 'eth_getBalance',
				"params": [wallet_address, "latest"]
			})
		)
	)

## Switch network
func switch_network(chain_name: String) -> void:
	if not SUPPORTED_CHAINS.has(chain_name):
		emit_signal("connection_failed", "Unsupported chain")
		return
	var chain_id = SUPPORTED_CHAINS[chain_name]
	var switch_sequence = Sequence.new(
		func(_args): prints("switched: ", chain_name), on_reject, true
	)
	switch_sequence.runasynic(
		window.ethereum.request(
			create_jsobj({ 
				"method": 'wallet_switchEthereumChain',
				"params": [{"chainId": chain_id}]
			})
		)
	)

## Initialize signer
func initialize_signer(response):
	window.signer = response  # check if this is safe

func on_reject():
	is_wallet_connected = false
	# Optionally, disconnect_wallet()
