extends Node

var resources = {
	"iron": 0,
	"wood": 0,
	"stone": 0
}

func add_resource(type: String, amount: int):
	resources[type] += amount
	print("Resources: ", resources)
