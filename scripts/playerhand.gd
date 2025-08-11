extends Node2D

# 常量定义 - 手牌系统的基础配置
const CARD_WIDTH = 200  # 单张卡牌的宽度（用于计算排列位置）
const HAND_Y_POSITION = 870  # 手牌在屏幕上的Y轴固定位置（底部区域）
const DEFAULT_CARD_MOVE_SPEED = 0.1

# 变量定义
var player_hand = []  # 存储玩家当前手牌的数组
var center_screen_x  # 屏幕中心的X坐标（用于手牌居中排列）

# 节点就绪时调用的初始化方法
func _ready() -> void:
	# 计算屏幕中心X坐标（用于后续手牌居中排列）
	center_screen_x = get_viewport().size.x / 2
	
	

# 将卡牌添加到手牌数组并更新布局
func add_card_to_hand(card,speed):
	# 检查卡牌是否已在手牌中，避免重复添加
	if card not in player_hand:
		# 将新卡牌插入到手牌数组的最前面（最新的牌在最左/最右）
		player_hand.insert(0, card)
		# 更新所有手牌的位置排列
		update_hand_positions(speed)
	else:
		# 如果卡牌已在手牌中，仅播放位置动画（用于恢复位置）
		animate_card_to_position(card, card.hand_position,DEFAULT_CARD_MOVE_SPEED)


# 更新所有手牌的位置，确保排列整齐
func update_hand_positions(speed):
	# 遍历手牌数组中的每张卡牌
	for i in range(player_hand.size()):
		# 计算当前索引卡牌的X坐标和固定Y坐标
		var new_position = Vector2(
			calculate_card_position(i),  # 动态计算X位置
			HAND_Y_POSITION  # 固定Y位置
		)
		
		# 获取当前卡牌并记录其目标位置
		var current_card = player_hand[i]
		current_card.hand_position = new_position  # 存储目标位置到卡牌自身属性
		
		# 播放卡牌移动到目标位置的动画
		animate_card_to_position(current_card, new_position,speed)


# 计算指定索引卡牌的X坐标，实现居中排列
func calculate_card_position(index):
	# 计算手牌整体占用的宽度（卡牌数量 × 单张宽度）
	var x_offset = (player_hand.size() - 1) * CARD_WIDTH
	# 计算当前卡牌的X坐标：以屏幕中心为基准，向左右均匀分布
	# 公式解析：center_screen_x（中心） + 索引偏移 - 总宽度的一半（实现居中）
	var x_position = center_screen_x + index * CARD_WIDTH - x_offset / 2
	return x_position


# 卡牌移动到目标位置的动画效果
func animate_card_to_position(card, new_position,speed):
	# 创建一个tween动画对象（Godot的动画系统）
	var tween = get_tree().create_tween()
	# 100毫秒内将卡牌位置平滑过渡到新位置
	tween.tween_property(card, "position", new_position, speed)


# 从手牌中移除指定卡牌并重新排列
func remove_card_from_hand(card):
	# 检查卡牌是否在手牌中
	if card in player_hand:
		# 从手牌数组中删除该卡牌
		player_hand.erase(card)
		# 重新计算并更新剩余手牌的位置
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
	
