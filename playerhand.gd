extends Node2D

const HAND_COUNT = 4 #手牌数量
const CARD_SCENE_PATH = "res://Scenes/cards.tscn" #手牌场景存储位置
const CARD_WIDTH = 200 #卡牌宽度
const HAND_Y_POSITION = 840 #手牌y坐标

var player_hand = [] #玩家手牌
var center_screen_x #屏幕中心x坐标

func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2 #获取屏幕中心x坐标
	
	var card_scene = preload(CARD_SCENE_PATH) #加载卡牌
	for i in range(HAND_COUNT): #初始化卡牌
		var new_card = card_scene.instantiate()
		$"../CardsManager".add_child(new_card)
		new_card.name = "Card"
		add_card_to_hand(new_card)


func add_card_to_hand(card): #将卡牌加入手牌
	if card not in player_hand:
		player_hand.insert(0,card)
		update_hand_positions()
	else:
		animate_card_to_position(card,card.hand_position)
	
	
	
func update_hand_positions(): #更新手牌位置
	for i in range(player_hand.size()): 
		var new_position = Vector2(calculate_card_position(i),HAND_Y_POSITION) #新卡牌位置,将卡牌居中
		var current_card = player_hand[i]
		current_card.hand_position = new_position
		animate_card_to_position(current_card,new_position)
		
		
func calculate_card_position(index): #计算卡牌居中位置
	var x_offset = (player_hand.size() - 1) * CARD_WIDTH
	var x_position = center_screen_x + index * CARD_WIDTH - x_offset / 2
	return x_position


func animate_card_to_position(card, new_position): #卡牌加入手牌动画
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",new_position,0.1)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions()
