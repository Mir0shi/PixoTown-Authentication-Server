extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1911
var max_servers = 5

func _ready():
	StartServer()
	
	
func StartServer():
	network.create_server(port, max_servers)
	get_tree().set_network_peer(network)
	print("Authenticate server started")
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")


func _Peer_Connected(gateway_id):
	print("Gateway " + str(gateway_id) + " Connected")


func _Peer_Disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " Disconnected")


remote func AuthenticatePlayer(username, password, player_id):
	var gateway_id = get_tree().get_rpc_sender_id()
	var hashed_password
	var token
	var result
	if not PlayerData.PlayerIDs.has(username):
		result = false
	else:
		var retrieved_salt = PlayerData.PlayerIDs[username].Salt
		hashed_password = GenerateHashedPassword(password, retrieved_salt)
		if not PlayerData.PlayerIDs[username].Password == hashed_password:
			result = false
		else:
			result = true
			
			randomize()
			token = str(randi()).sha256_text() + str(OS.get_unix_time())
			var gameserver = "GameServer1"
			GameServers.DistributeLoginToken(token, gameserver, username)
	print("Authentication result send to gateway server")
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)

remote func CreateAccount(username, password, player_id):
	var gateway_id = get_tree().get_rpc_sender_id()
	var result
	var message
	if PlayerData.PlayerIDs.has(username):
		result = false
		message = 2
	else:
		result = true
		message = 3
		var salt = GenerateSalt()
		var hashed_password = GenerateHashedPassword(password, salt)
		PlayerData.PlayerIDs[username] = {"Password": hashed_password, "Salt": salt}
		PlayerData.SavePlayerIDs()
	
	rpc_id(gateway_id, "CreateAccountResults", result, player_id, message)


func GenerateSalt():
	randomize()
	var salt = str(randi()).sha256_text()
	print("Salt: " + salt)
	return salt

func GenerateHashedPassword(password, salt):
	print(str(OS.get_system_time_msecs()))
	var hashed_password = password
	var rounds = pow(2, 19)
	print(rounds)
	print("Hashed password as input: " + hashed_password)
	while rounds > 0:
		hashed_password = (hashed_password + salt).sha256_text()
		rounds -= 1
	print("Final Hashed password: " + hashed_password)
	print(str(OS.get_system_time_msecs()))
	return hashed_password
