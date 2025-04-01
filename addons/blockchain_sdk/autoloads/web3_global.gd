extends Node

signal wallet_connected(address: String)
signal wallet_error(error: String)

var popup_menu: Control
var wallet_address_label: Label

func _ready():
    create_popup_menu()

func create_popup_menu():
    popup_menu = Control.new()
    popup_menu.set_anchors_preset(Control.PRESET_CENTER)
    popup_menu.set_size(Vector2(250, 120))
    popup_menu.modulate = Color(1, 1, 1, 1)  # White background
    popup_menu.visible = true  # Show menu at start

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

    popup_menu.add_child(label)
    popup_menu.add_child(button_yes)
    popup_menu.add_child(button_no)
    popup_menu.add_child(wallet_address_label)

    add_child(popup_menu)

func _on_connect_wallet_pressed():
    popup_menu.visible = false  # Hide menu immediately after clicking
    connect_wallet()

func _on_close_popup():
    popup_menu.visible = false  # Hide menu

func connect_wallet():
    if not OS.has_feature("web"):
        print("Wallet connection only available in web builds")
        return

    # Call JavaScript to connect MetaMask
    var script = """
        (async () => {
            if (typeof window.ethereum !== "undefined") {
                try {
                    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                    return accounts[0]; // Return first wallet address
                } catch (error) {
                    console.error("MetaMask connection error:", error);
                    return "error";
                }
            } else {
                return "no_metamask";
            }
        })();
    """

    var result = JavaScriptBridge.eval(script, true)  # Runs JavaScript and waits for result

    if result == "no_metamask":
        print("MetaMask not installed")
        wallet_error.emit("MetaMask not installed")
    elif result == "error":
        print("Wallet connection failed")
        wallet_error.emit("Wallet connection failed")
    else:
        wallet_address_label.text = "Wallet: " + result
        wallet_address_label.visible = true
        wallet_connected.emit(result)  # Emit signal with address
