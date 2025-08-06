# 桌面牌堆管理器脚本
# 负责管理玩家牌堆（牌库）的状态，处理抽卡逻辑，以及更新牌堆UI显示
extends Node2D

# 常量定义
const CARD_SCENE_PATH = "res://Scenes/cards.tscn"  # 卡牌场景资源路径（用于实例化新卡牌）
const CARD_DRAW_SPEED = 0.5                        # 抽卡动画的速度参数（控制卡牌移动到手牌的平滑度）

# 玩家牌堆数据（存储待抽取的卡牌名称/ID，示例初始为3张"Doctor"卡牌）
var player_deck = ["doctor", "chara2", "chara3"]
var card_database_reference

# 节点就绪时调用（初始化UI显示）
func _ready() -> void:
	player_deck.shuffle()
	# 初始化显示牌堆剩余卡牌数量（通过RichTextLabel组件展示）
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://scripts/CardDatabase.gd")


# 抽卡逻辑：从牌堆取出一张卡牌并添加到手牌
func draw_card():
	# 从牌堆顶部（数组第一个元素）抽取一张卡牌
	var card_drawn_name = player_deck[0]
	# 从牌堆中移除已抽取的卡牌
	player_deck.erase(card_drawn_name)
	
	# 如果牌堆为空（没有剩余卡牌）
	if player_deck.size() == 0:
		# 禁用牌堆的碰撞体（防止玩家继续点击抽卡）
		$Area2D/CollisionShape2D.disabled = true
		# 隐藏牌堆的精灵图像（视觉上表示牌堆已空）
		$Sprite2D.visible = false
		# 隐藏剩余数量文本（无需再显示0）
		$RichTextLabel.visible = false
	
	# 更新牌堆剩余数量的UI显示
	$RichTextLabel.text = str(player_deck.size())
	
	# 预加载卡牌场景（提前加载资源，避免实例化时卡顿）
	var card_scene = preload(CARD_SCENE_PATH)
	# 实例化新卡牌节点（从预加载的场景创建具体卡牌对象）
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://assets/cardsimage/" + card_drawn_name + ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.get_node("Attack").text=str(card_database_reference.CARDS[card_drawn_name][0])
	new_card.get_node("Health").text=str(card_database_reference.CARDS[card_drawn_name][1])
	# 将新卡牌添加到卡牌管理器节点（由CardsManager统一管理交互逻辑）
	$"../CardsManager".add_child(new_card)
	# 为新卡牌设置名称（便于调试时识别，可根据实际卡牌类型动态命名）
	new_card.name = "Card"
	# 将新卡牌添加到手牌系统（由PlayerHand处理卡牌在手牌中的排列和位置）
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("cardflip")
