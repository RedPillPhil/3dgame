var _result: String = ""  # Variable to store wallet address result

func connect_wallet():
	if not OS.has_feature("web"):
		print("Wallet connection only available in web builds")
		return
	
	# Define a JavaScript function that calls the callback
	var script = """
		ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => {
			if (accounts.length > 0) {
				// Set the global variable with the wallet address
				window.wallet_address_result = accounts[0];
				console.log('Wallet address found:', accounts[0]);  // Debugging
			} else {
				window.wallet_address_result = 'No account found';
				console.log('No account found');  // Debugging
			}
		}).catch(() => {
			window.wallet_address_result = 'error';
			console.log('Error occurred in wallet connection');  // Debugging
		});
	"""

	# Execute the script (this will run and set the global wallet_address_result variable)
	print("Executing script to request wallet address...")  # Debugging
	JavaScriptBridge.eval(script)

	# Wait for a frame to ensure the script has executed and the result is set
	await get_tree().idle_frame  # Wait for the next frame
	print("Finished waiting for script execution.")  # Debugging

	# Retrieve the wallet address from the global result variable set by JavaScript
	_result = JavaScriptBridge.eval("window.wallet_address_result")  # Fetch the result
	print("Wallet connection result: ", _result)  # Debugging

	# Check the result and update UI accordingly
	if _result == "error":
		print("Wallet connection failed.")  # Debugging
		status_label.text = "Failed."
	elif _result == "No account found":
		print("No account found.")  # Debugging
		status_label.text = "No account found."
	else:
		# Successfully connected, update label
		print("Successfully connected wallet address: ", _result)  # Debugging
		wallet_address = _result
		is_wallet_connected = true
		status_label.text = "Wallet connected"
		status_label.visible = false  # Hide the "Fetching User Address" status
		wallet_address_label.text = "Wallet: " + wallet_address
		wallet_address_label.visible = true
		popup_menu.visible = false  # Hide the popup after connection
